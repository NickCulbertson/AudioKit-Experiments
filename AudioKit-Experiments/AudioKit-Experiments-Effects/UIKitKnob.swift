import Foundation
import UIKit
import CoreGraphics

@IBDesignable
public class UIKitKnob: UIView {

    public var callback: (Double) -> Void = { _ in }
    public var callbackBool: (Bool) -> Void = { _ in }

    public var taper: Double = 1.0 // Linear by default
    public var originKnobValue: CGFloat = 0.0
    public var presetKnobValue: CGFloat = 0.0
    public var labelUpdating = false
    public var presetUpdating = false
    
    public var _value: Double = 0
    
    var isInterfaceBuilder: Bool = false

    public override func prepareForInterfaceBuilder() {
        self.isInterfaceBuilder = true
        super.prepareForInterfaceBuilder()

        contentMode = .scaleAspectFit
        clipsToBounds = true
    }
    
    var value: Double {
        get {
            return _value
        }
        set(newValue) {
            let previousval = self.knobValue
            _value = min(max(0, newValue),1)
            let newval = _value
            if presetUpdating {
            for i in 0...10 {
                if self.isInterfaceBuilder {
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.025 * Double(i)) {
                    self.knobValue = min(max(0, (1 - Double(i) * 0.1) * previousval + Double(i) * 0.1 * newval),1)
                    print(self.knobValue)
                    if i == 10 {
                        self.presetUpdating = false
                    }
                       }
                    
                }
            }else{
                self.knobValue = _value
            }
        }
    }
    

    // Knob properties
    var knobValue: CGFloat = 0.0 {
        didSet(newValue) {
            _value = min(max(0, newValue),1)
            print("knob value \(_value)")
            if self.isInterfaceBuilder {
                return
            }
            let angle = CGFloat(.pi * Float(value * 1.65)+0.55) // 90 degrees, in radians
                UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
                    self.Knob1Image.transform = CGAffineTransform(rotationAngle: angle)
                }, completion: { finished in
                    
                })
                
                self.setNeedsDisplay()
            
        }
    }

    // Alternative to .knobValue = with no setNeedsDisplay
    func changeValue(_ newValue: Double) {
        _value = newValue
    }

    var knobFill: CGFloat = 0
    var knobSensitivity: CGFloat = 0.005
    var lastX: CGFloat = 0
    var lastY: CGFloat = 0
    var Knob1Image = UIImageView()

    // Init / Lifecycle
    override init(frame: CGRect) {
        
        super.init(frame: frame)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.isUserInteractionEnabled = true
        if self.isInterfaceBuilder {
            return
        }
        //Setup View
        Knob1Image.image = UIImage(named: "SynthKnobLarge")
        Knob1Image.contentMode = .scaleAspectFill // Set the content mode to fill the image view
        Knob1Image.clipsToBounds = true
        Knob1Image.translatesAutoresizingMaskIntoConstraints = false
        addSubview(Knob1Image)
        
        // Add constraints to the image view
        NSLayoutConstraint.activate([
            Knob1Image.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            Knob1Image.topAnchor.constraint(equalTo: self.topAnchor),
            Knob1Image.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            Knob1Image.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        // Add double tap listener
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        self.addGestureRecognizer(tap)
    }

    

    @objc func doubleTapped() {
        updateKnobValue(Double(presetKnobValue))
    }

    public class override var requiresConstraintBasedLayout: Bool {
        return true
    }

    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                labelUpdating = true
                let touchPoint = touch.location(in: self)
                lastX = touchPoint.x
                lastY = touchPoint.y
            }
        }

        override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            for touch in touches {
                let touchPoint = touch.location(in: self)
                setPercentagesWithTouchPoint(touchPoint)
            }
        }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            labelUpdating = false
        callbackBool(false)
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            labelUpdating = false
        callbackBool(false)
        
    }
    
    // Helper
    func setPercentagesWithTouchPoint(_ touchPoint: CGPoint) {
        // Knobs assume up or right is increasing, and down or left is decreasing
        knobValue += (touchPoint.x - lastX) * knobSensitivity
        knobValue -= (touchPoint.y - lastY) * knobSensitivity

        value = knobValue

        originKnobValue = knobValue // set last user set position to originKnobValue
        callback(value)
        lastX = touchPoint.x
        lastY = touchPoint.y
    }

    func setKnobValue(_ newValue: Double) {
        presetKnobValue = CGFloat(newValue)
        updateKnobValue(newValue)
    }

    func updateKnobValue(_ newValue: Double, resetOrigin: Bool = true) {
        knobValue = CGFloat(newValue)
        _value = newValue
        originKnobValue = knobValue
        callback(_value)
        self.setNeedsDisplay()
    }

    func setOriginValue(_ newValue: Double) {
        knobValue = CGFloat(newValue)
        originKnobValue = knobValue
    }

}
