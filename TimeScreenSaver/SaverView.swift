import Cocoa
import ScreenSaver

class SaverView: ScreenSaverView {
    
    // Timer to update the screen saver every second
    var timer: Timer?
    
    // Variables to control position and movement direction
    var currentX: CGFloat = 0.0
    var currentY: CGFloat = 0.0
    var directionX: CGFloat = 1.0
    var directionY: CGFloat = 1.0
    var speed: CGFloat = 2.0
    
    // Animation phases
    enum AnimationPhase {
        case bottomLeftToTopCenter
        case topCenterToBottomRight
        case bottomRightToTopCenter
        case topCenterToBottomLeft
    }
    
    var currentPhase: AnimationPhase = .bottomLeftToTopCenter
    
    // Positions to move between
    let bottomLeft = CGPoint(x: 0, y: 0)
    var topCenter: CGPoint {
        return CGPoint(x: ((self.bounds.size.width - 250) / 2), y: self.bounds.size.height - 60) // Updated to be dynamic
    }
    
    var bottomRight: CGPoint {
        return CGPoint(x: self.bounds.size.width - 250, y: 0)
    }
    
    // Initialize the view
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.wantsLayer = true
        
        logToFile("init")

        DistributedNotificationCenter.default.addObserver(self,
                                                          selector: #selector(stopVideo),
                                                          name: NSNotification.Name("com.apple.screensaver.didstop"),
                                                          object: nil)
        
        
        // Start the timer to update the time every second
        timer = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        //logToFile("deinit: \(player)")
        DistributedNotificationCenter.default.removeObserver(self)
    }
    
    override func startAnimation() {
        super.startAnimation()
        logToFile("startAnimation")

        DispatchQueue.main.async {
            self.updateTime()
        }
    }
    
    override func animateOneFrame() {
        super.animateOneFrame()
        updateTime()
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        
        logToFile("stopAnimation")
    }
    
    
    
    @objc func stopVideo() {
        
        logToFile("stopVideo \(isPreview)")
    }
    
    // Function to update the screen saver (called every frame)
    @objc func updateTime() {
        switch currentPhase {
        case .bottomLeftToTopCenter:
            // Move diagonally from bottom-left to top-center
            moveDiagonally(from: bottomLeft, to: topCenter)
            if currentX >= topCenter.x - 5 && currentY >= topCenter.y - 5 {
                currentPhase = .topCenterToBottomRight
            }
            
        case .topCenterToBottomRight:
            // Move diagonally from top-center to bottom-right
            moveDiagonally(from: topCenter, to: bottomRight)
            if currentX >= bottomRight.x - 5 && currentY <= bottomRight.y + 5 {
                currentPhase = .bottomRightToTopCenter
            }
            
        case .bottomRightToTopCenter:
            // Move diagonally from bottom-right to top-center
            moveDiagonally(from: bottomRight, to: topCenter)
            if currentX <= topCenter.x + 5 && currentY >= topCenter.y - 5 {
                currentPhase = .topCenterToBottomLeft
            }
            
        case .topCenterToBottomLeft:
            // Move diagonally from top-center to bottom-left
            moveDiagonally(from: topCenter, to: bottomLeft)
            if currentX <= bottomLeft.x + 5 && currentY <= bottomLeft.y + 5 {
                currentPhase = .bottomLeftToTopCenter
            }
        }
        
        // Trigger a redraw
        self.setNeedsDisplay(self.bounds)
        self.displayIfNeeded()
    }
    
    // Function to move the text diagonally
    func moveDiagonally(from startPoint: CGPoint, to endPoint: CGPoint) {
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        
        // Normalize the movement
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
        let stepX = deltaX / distance * speed
        let stepY = deltaY / distance * speed
        
        // Update the position
        currentX += stepX
        currentY += stepY
    }
    
    
    func dynamicFontSize(size: CGFloat) -> CGFloat {
        return 100 * (size / self.bounds.size.width)
    }
    
    // Function to draw the time
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        // Set background color (optional)
        NSColor.black.setFill()
        rect.fill()
        
        // Set text color (white)
        NSColor.white.set()
        
        logToFile("ispreview \(isPreview)")
        
        // Set the font style and size
        let font = NSFont.systemFont(ofSize: 60)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        
        // Format current time
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss" // Format: 24-hour time with seconds
        let timeString = formatter.string(from: Date())
        
        // Calculate the size of the text
        let textSize = timeString.size(withAttributes: attributes)
        
        // Position the text based on currentX and currentY
        let textRect = NSRect(
            x: currentX,
            y: currentY,
            width: textSize.width,
            height: textSize.height
        )
        
        // Draw the time string
        timeString.draw(in: textRect, withAttributes: attributes)
    }
    
    
    func logToFile(_ message: String) {
        guard let filePath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return
        }
        let logFilePath = filePath.appendingPathComponent("log.txt")//"/Users/mqs_2/Downloads/log.txt"
        let logMessage = "\(Date()): \(message)\n"
        if let fileHandle = FileHandle(forWritingAtPath: logFilePath.path) {
            fileHandle.seekToEndOfFile()
            if let data = logMessage.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            try? logMessage.write(toFile: logFilePath.path, atomically: true, encoding: .utf8)
        }
    }
}
