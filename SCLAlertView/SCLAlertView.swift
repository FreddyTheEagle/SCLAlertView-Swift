import Foundation
import UIKit

// Animation Styles
public enum SCLAnimationStyle {
    case noAnimation, topToBottom, bottomToTop, leftToRight, rightToLeft
}

// Action Types
public enum SCLActionType {
    case none, selector, closure
}

public enum SCLAlertButtonLayout {
    case horizontal, vertical
}

let kCircleHeightBackground: CGFloat = 62.0
let uniqueTag: Int = Int(arc4random() % UInt32(Int32.max))
let uniqueAccessibilityIdentifier: String = "SCLAlertView"

public typealias DismissBlock = () -> Void

open class SCLAlertView: UIViewController {
    public struct SCLTimeoutConfiguration {
        public typealias ActionType = () -> Void
        
        var value: TimeInterval
        let action: ActionType
        
        mutating func increaseValue(by: Double) {
            self.value = value + by
        }
        
        public init(timeoutValue: TimeInterval, timeoutAction: @escaping ActionType) {
            self.value = timeoutValue
            self.action = timeoutAction
        }
    }
    
    let type: SCLAlertViewType
    let mainText: String
    var appearance: SCLAppearance
    
    var viewColor = UIColor()
    
    open var iconTintColor: UIColor?
    open var customSubview : UIView?
    
    // Members declaration
    var baseView = UIView()
    var labelTitle = UILabel()
    var viewText = UITextView()
    var contentView = UIView()
    var circleBG = UIView(frame: CGRect(x: 0, y: 0, width: kCircleHeightBackground, height: kCircleHeightBackground))
    var circleView = UIView()
    var circleIconView: UIView?
    var timeout: SCLTimeoutConfiguration?
    var showTimeoutTimer: Timer?
    var timeoutTimer: Timer?
    var dismissBlock: DismissBlock?
    
    fileprivate var inputs = [UITextField]()
    fileprivate var input = [UITextView]()
    internal var buttons = [SCLButton]()
    fileprivate var selfReference: SCLAlertView?
    
    public init(type: SCLAlertViewType, mainText: String) {
        self.type = type
        self.appearance = SCLAppearance()
        self.mainText = mainText
        
        super.init(nibName: nil, bundle: nil)
        
        setup()
    }
    
    public init(type: SCLAlertViewType, mainText: String, appearance: SCLAppearance) {
        self.type = type
        self.mainText = mainText
        self.appearance = appearance
        
        super.init(nibName:nil, bundle:nil)
        
        setup()
    }
    
    required public init() {
        self.type = .info
        self.mainText = ""
        self.appearance = SCLAppearance()

        super.init(nibName: nil, bundle: nil)

        setup()
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.type = .info
        self.mainText = ""
        self.appearance = SCLAppearance()
        
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    fileprivate func setup() {
        view.frame = UIScreen.main.bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:appearance.kDefaultShadowOpacity)
        view.addSubview(baseView)
        
        baseView.frame = view.frame
        baseView.addSubview(contentView)
        
        contentView.layer.cornerRadius = appearance.contentViewCornerRadius
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.addSubview(labelTitle)
        contentView.addSubview(viewText)
        
        circleBG.backgroundColor = appearance.circleBackgroundColor
        circleBG.layer.cornerRadius = circleBG.frame.size.height / 2
        baseView.addSubview(circleBG)
        circleBG.addSubview(circleView)
        
        let x = (kCircleHeightBackground - appearance.kCircleHeight) / 2
        circleView.frame = CGRect(x:x, y:x+appearance.kCircleTopPosition, width:appearance.kCircleHeight, height:appearance.kCircleHeight)
        circleView.layer.cornerRadius = circleView.frame.size.height / 2
        
        labelTitle.text = mainText
        labelTitle.numberOfLines = 0
        labelTitle.textAlignment = .center
        labelTitle.backgroundColor = .magenta
        labelTitle.font = appearance.kTitleFont
        
        if (appearance.kTitleMinimumScaleFactor < 1) {
            labelTitle.minimumScaleFactor = appearance.kTitleMinimumScaleFactor
            labelTitle.adjustsFontSizeToFitWidth = true
        }
        
        viewText.isEditable = false
        viewText.textAlignment = .center
        viewText.textContainerInset = UIEdgeInsets.zero
        viewText.textContainer.lineFragmentPadding = 0;
        viewText.font = appearance.kTextFont
        
        contentView.backgroundColor = appearance.contentViewColor
        viewText.backgroundColor = appearance.contentViewColor
        labelTitle.textColor = appearance.titleColor
        viewText.textColor = appearance.titleColor
        contentView.layer.borderColor = appearance.contentViewBorderColor.cgColor
        
        if appearance.disableTapGesture == false {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(SCLAlertView.tapped(_:)))
            tapGesture.numberOfTapsRequired = 1
            self.view.addGestureRecognizer(tapGesture)
        }
    }
    
    private var isPad: Bool {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .tv, .carPlay, .unspecified: return false
        case .pad: return true
        }
    }
    
    private var isLandscape: Bool {
        switch UIDevice.current.orientation {
        case .unknown, .portrait, .portraitUpsideDown, .faceUp, .faceDown: return false
        case .landscapeLeft, .landscapeRight: return true
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let screenRect = UIScreen.main.bounds
        let multiplication: (width: CGFloat, height: CGFloat)
        
        switch (isPad, isLandscape) {
        case (true, true): multiplication = (0.4, 0.4)
        case (true, false): multiplication = (0.6, 0.5)
        case (false, true): multiplication = (0.5, 0.3)
        case (false, false): multiplication = (0.8, 0.5)
        }
        
        appearance.kWindowWidth = multiplication.width * screenRect.width
        appearance.kWindowHeight = multiplication.height * screenRect.height
        appearance.kTextViewdHeight = 0.5 * appearance.kWindowHeight
        appearance.buttonsLayout = isPad ? .horizontal : .vertical
        
        labelTitle.sizeToFit()
//        labelTitle.center.x = contentView.center.x
        labelTitle.center = CGPoint(x: (contentView.frame.width - labelTitle.frame.width) / 2,
                                    y: appearance.showCircularIcon ? 0.0 : 12.0)
        
        let rv = UIApplication.shared.keyWindow! as UIWindow
        let sz = rv.frame.size
        
        view.frame.size = sz
        
        let hMargin: CGFloat = 12
        let defaultTopOffset: CGFloat = 32
        
        var titleActualHeight: CGFloat = 0
        
        if let title = labelTitle.text {
            titleActualHeight = title.heightWithConstrainedWidth(width: appearance.kWindowWidth - hMargin * 2, font: labelTitle.font) + 10
            titleActualHeight = (titleActualHeight > appearance.kTitleHeight ? titleActualHeight : appearance.kTitleHeight)
        }
        
        let maxHeight = sz.height - 100
        var consumedHeight = CGFloat(0)
        
        consumedHeight += (titleActualHeight > 0 ? appearance.kTitleTop + titleActualHeight : defaultTopOffset)
        consumedHeight += 14
        
        if appearance.buttonsLayout == .vertical {
            consumedHeight += appearance.kButtonHeight * CGFloat(buttons.count)
        } else {
            consumedHeight += appearance.kButtonHeight
        }
        consumedHeight += appearance.kTextFieldHeight * CGFloat(inputs.count)
        consumedHeight += appearance.kTextViewdHeight * CGFloat(input.count)
        
        let maxViewTextHeight = maxHeight - consumedHeight
        let viewTextWidth = appearance.kWindowWidth - hMargin * 2
        var viewTextHeight = appearance.kTextHeight
        
        if let customSubview = customSubview {
            viewTextHeight = min(customSubview.frame.height, maxViewTextHeight)
            viewText.text = ""
            viewText.addSubview(customSubview)
        } else {
            // computing the right size to use for the textView
            let suggestedViewTextSize = viewText.sizeThatFits(CGSize(width: viewTextWidth, height: CGFloat.greatestFiniteMagnitude))
            viewTextHeight = min(suggestedViewTextSize.height, maxViewTextHeight)
            
            // scroll management
            if (suggestedViewTextSize.height > maxViewTextHeight) {
                viewText.isScrollEnabled = true
            } else {
                viewText.isScrollEnabled = false
            }
        }
        
        let windowHeight = consumedHeight + viewTextHeight
        // Set frames
        var x = (sz.width - appearance.kWindowWidth) / 2
        var y = (sz.height - windowHeight - (appearance.kCircleHeight / 8) - 170) / 2
        contentView.frame = CGRect(x:x, y:y, width:appearance.kWindowWidth, height:windowHeight)
        contentView.layer.cornerRadius = appearance.contentViewCornerRadius
        y -= kCircleHeightBackground * 0.6
        x = (sz.width - kCircleHeightBackground) / 2
        circleBG.frame = CGRect(x:x, y:y+appearance.kCircleBackgroundTopPosition, width:kCircleHeightBackground, height:kCircleHeightBackground)
        
        // Subtitle
        y = titleActualHeight > 0 ? appearance.kTitleTop + titleActualHeight + labelTitle.frame.origin.y : defaultTopOffset
        viewText.frame = CGRect(x: hMargin, y: y, width: appearance.kWindowWidth - hMargin * 2, height: appearance.kTextHeight)
        viewText.frame = CGRect(x: hMargin, y: y, width: viewTextWidth, height: viewTextHeight)
        
        // Text fields
        y += viewTextHeight + 14.0
        for txt in inputs {
            txt.frame = CGRect(x:hMargin, y: y, width: appearance.kWindowWidth - hMargin * 2, height: 30)
            txt.layer.cornerRadius = appearance.fieldCornerRadius
            y += appearance.kTextFieldHeight
        }
        
        for txt in input {
            txt.frame = CGRect(x:hMargin, y: y, width: appearance.kWindowWidth - hMargin * 2, height: appearance.kTextViewdHeight - hMargin)
            //txt.layer.cornerRadius = fieldCornerRadius
            y += appearance.kTextViewdHeight
        }
        
        // Buttons
        let numberOfButton = CGFloat(buttons.count)
        let buttonsSpace = numberOfButton >= 1 ? CGFloat(10) * (numberOfButton - 1) : 0
        let widthEachButton = (appearance.kWindowWidth - 24 - buttonsSpace) / numberOfButton
        var buttonX = CGFloat(12)
        
        switch appearance.buttonsLayout {
        case .vertical:
            for btn in buttons {
                btn.frame = CGRect(x:12, y:y, width:appearance.kWindowWidth - 24, height:35)
                btn.layer.cornerRadius = appearance.buttonCornerRadius
                y += appearance.kButtonHeight
            }
        case .horizontal:
            for btn in buttons {
                btn.frame = CGRect(x:buttonX, y:y, width: widthEachButton, height:35)
                btn.layer.cornerRadius = appearance.buttonCornerRadius
                buttonX += widthEachButton
                buttonX += buttonsSpace
            }
        }
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(SCLAlertView.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(SCLAlertView.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override open func touchesEnded(_ touches:Set<UITouch>, with event:UIEvent?) {
        if event?.touches(for: view)?.count > 0 {
            view.endEditing(true)
        }
    }
    
    open func addTextField(_ title: String? = nil) -> UITextField {
        // Update view height
        appearance.setkWindowHeight(appearance.kWindowHeight + appearance.kTextFieldHeight)
        // Add text field
        let txt = UITextField()
        txt.borderStyle = UITextBorderStyle.roundedRect
        txt.font = appearance.kTextFont
        txt.autocapitalizationType = UITextAutocapitalizationType.words
        txt.clearButtonMode = UITextFieldViewMode.whileEditing
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        
        if title != nil {
            txt.placeholder = title!
        }
        
        contentView.addSubview(txt)
        inputs.append(txt)
        return txt
    }
    
    open func addTextView()->UITextView {
        // Update view height
        appearance.setkWindowHeight(appearance.kWindowHeight + appearance.kTextViewdHeight)
        // Add text view
        let txt = UITextView()
        // No placeholder with UITextView but you can use KMPlaceholderTextView library 
        txt.font = appearance.kTextFont
        //txt.autocapitalizationType = UITextAutocapitalizationType.Words
        //txt.clearButtonMode = UITextFieldViewMode.WhileEditing
        txt.layer.masksToBounds = true
        txt.layer.borderWidth = 1.0
        contentView.addSubview(txt)
        input.append(txt)
        return txt
    }
    
    @discardableResult
    open func addButton(_ title: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil, showTimeout: SCLButton.ShowTimeoutConfiguration? = nil, action: @escaping () -> Void) -> SCLButton {
        let btn = addButton(title, backgroundColor: backgroundColor, textColor: textColor, showTimeout: showTimeout)
        btn.actionType = SCLActionType.closure
        btn.action = action
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapped(_:)), for:.touchUpInside)
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapDown(_:)), for:[.touchDown, .touchDragEnter])
        btn.addTarget(self, action:#selector(SCLAlertView.buttonRelease(_:)), for:[.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside] )
        return btn
    }
    
    @discardableResult
    open func addButton(_ title: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil, showTimeout: SCLButton.ShowTimeoutConfiguration? = nil, target: AnyObject, selector: Selector) -> SCLButton {
        let btn = addButton(title, backgroundColor: backgroundColor, textColor: textColor, showTimeout: showTimeout)
        btn.actionType = SCLActionType.selector
        btn.target = target
        btn.selector = selector
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapped(_:)), for:.touchUpInside)
        btn.addTarget(self, action:#selector(SCLAlertView.buttonTapDown(_:)), for:[.touchDown, .touchDragEnter])
        btn.addTarget(self, action:#selector(SCLAlertView.buttonRelease(_:)), for:[.touchUpInside, .touchUpOutside, .touchCancel, .touchDragOutside] )
        return btn
    }
    
    @discardableResult
    fileprivate func addButton(_ title: String, backgroundColor: UIColor? = nil, textColor: UIColor? = nil, showTimeout: SCLButton.ShowTimeoutConfiguration? = nil) -> SCLButton {
        // Update view height
        appearance.setkWindowHeight(appearance.kWindowHeight + appearance.kButtonHeight)
        // Add button
        let btn = SCLButton()
        btn.layer.masksToBounds = true
        btn.setTitle(title, for: UIControlState())
        btn.titleLabel?.font = appearance.kButtonFont
        btn.customBackgroundColor = backgroundColor
        btn.customTextColor = textColor
        btn.initialTitle = title
        btn.showTimeout = showTimeout
        contentView.addSubview(btn)
        buttons.append(btn)
        return btn
    }
    
    @objc func buttonTapped(_ btn: SCLButton) {
        if btn.actionType == SCLActionType.closure {
            btn.action()
        } else if btn.actionType == SCLActionType.selector {
            let ctrl = UIControl()
            ctrl.sendAction(btn.selector, to:btn.target, for:nil)
        } else {
            print("Unknow action type for button")
        }
        
        if(self.view.alpha != 0.0 && appearance.shouldAutoDismiss){ hideView() }
    }
    
    
    @objc func buttonTapDown(_ btn: SCLButton) {
        var hue : CGFloat = 0
        var saturation : CGFloat = 0
        var brightness : CGFloat = 0
        var alpha : CGFloat = 0
        let pressBrightnessFactor = 0.85
        btn.backgroundColor?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness = brightness * CGFloat(pressBrightnessFactor)
        btn.backgroundColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
    
    @objc func buttonRelease(_ btn: SCLButton) {
        btn.backgroundColor = btn.customBackgroundColor ?? viewColor
    }
    
    var tmpContentViewFrameOrigin: CGPoint?
    var tmpCircleViewFrameOrigin: CGPoint?
    var keyboardHasBeenShown: Bool = false
    
    @objc func keyboardWillShow(_ notification: Notification) {
        keyboardHasBeenShown = true
        
        guard let userInfo = (notification as NSNotification).userInfo,
            let endKeyBoardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.minY else {
                return
        }
        
        if tmpContentViewFrameOrigin == nil {
            tmpContentViewFrameOrigin = self.contentView.frame.origin
        }
        
        if tmpCircleViewFrameOrigin == nil {
            tmpCircleViewFrameOrigin = self.circleBG.frame.origin
        }
        
        var newContentViewFrameY = self.contentView.frame.maxY - endKeyBoardFrame
        
        if newContentViewFrameY < 0 {
            newContentViewFrameY = 0
        }
        
        let newBallViewFrameY = self.circleBG.frame.origin.y - newContentViewFrameY
        self.contentView.frame.origin.y -= newContentViewFrameY
        self.circleBG.frame.origin.y = newBallViewFrameY
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if (keyboardHasBeenShown) { //This could happen on the simulator (keyboard will be hidden)
            if (self.tmpContentViewFrameOrigin != nil) {
                self.contentView.frame.origin.y = self.tmpContentViewFrameOrigin!.y
                self.tmpContentViewFrameOrigin = nil
            }
            
            if (self.tmpCircleViewFrameOrigin != nil) {
                self.circleBG.frame.origin.y = self.tmpCircleViewFrameOrigin!.y
                self.tmpCircleViewFrameOrigin = nil
            }
            
            keyboardHasBeenShown = false
        }
    }
    
    //Dismiss keyboard when tapped outside textfield & close SCLAlertView when hideWhenBackgroundViewIsTapped
    @objc func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
        
        if let tappedView = gestureRecognizer.view , tappedView.hitTest(gestureRecognizer.location(in: tappedView), with: nil) == baseView && appearance.hideWhenBackgroundViewIsTapped {
            
            hideView()
        }
    }
    
    @discardableResult
    open func show(subTitle: String, closeButtonTitle: String? = nil, timeout: SCLTimeoutConfiguration? = nil, animationStyle: SCLAnimationStyle = .topToBottom) -> SCLAlertViewResponder {
        selfReference = self
        view.alpha = 0
        view.tag = uniqueTag
        view.accessibilityIdentifier = uniqueAccessibilityIdentifier
        
        let rv = UIApplication.shared.keyWindow! as UIWindow
        rv.addSubview(view)
        view.frame = rv.bounds
        baseView.frame = rv.bounds
        
        // Alert colour/icon
        viewColor = UIColor()
        var iconImage: UIImage?
        let colorInt = type.defaultColor
        viewColor = UIColorFromRGB(colorInt)
        
        // Subtitle
        if !subTitle.isEmpty {
            viewText.text = subTitle
            // Adjust text view size, if necessary
            let str = subTitle as NSString
            let attr = [NSAttributedStringKey.font: viewText.font ?? UIFont()]
            let sz = CGSize(width: appearance.kWindowWidth - 24, height:90)
            let r = str.boundingRect(with: sz, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes:attr, context:nil)
            let ht = ceil(r.size.height)
            if ht < appearance.kTextHeight {
                appearance.kWindowHeight -= (appearance.kTextHeight - ht)
                appearance.setkTextHeight(ht)
            }
        }
        
        //hidden/show circular view based on the ui option
        circleView.isHidden = !appearance.showCircularIcon
        circleBG.isHidden = !appearance.showCircularIcon
        
        // Alert view colour and images
        circleView.backgroundColor = viewColor
        
        // Spinner / icon
        if type == .wait {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            indicator.startAnimating()
            circleIconView = indicator
        } else {
            if let iconTintColor = iconTintColor {
                circleIconView = UIImageView(image: type.image?.withRenderingMode(.alwaysTemplate))
                circleIconView?.tintColor = iconTintColor
            } else {
                circleIconView = UIImageView(image: type.image)
            }
        }
        
        circleView.addSubview(circleIconView!)
        let x = (appearance.kCircleHeight - appearance.kCircleIconHeight) / 2
        circleIconView!.frame = CGRect( x: x, y: x, width: appearance.kCircleIconHeight, height: appearance.kCircleIconHeight)
        circleIconView?.layer.masksToBounds = true
        
        for txt in inputs {
            txt.layer.borderColor = viewColor.cgColor
        }
        
        for txt in input {
            txt.layer.borderColor = viewColor.cgColor
        }
        
        for btn in buttons {
            if let customBackgroundColor = btn.customBackgroundColor {
                // Custom BackgroundColor set
                btn.backgroundColor = customBackgroundColor
            } else {
                // Use default BackgroundColor derived from AlertStyle
                btn.backgroundColor = viewColor
            }
            
            if let customTextColor = btn.customTextColor {
                // Custom TextColor set
                btn.setTitleColor(customTextColor, for:UIControlState())
            } else {
                // Use default BackgroundColor derived from AlertStyle
                btn.setTitleColor(UIColorFromRGB(type.colorTextButton), for: UIControlState())
            }
        }
        
        // Adding timeout
        if let timeout = timeout {
            self.timeout = timeout
            timeoutTimer?.invalidate()
            timeoutTimer = Timer.scheduledTimer(timeInterval: timeout.value, target: self, selector: #selector(SCLAlertView.hideViewTimeout), userInfo: nil, repeats: false)
            showTimeoutTimer?.invalidate()
            showTimeoutTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(SCLAlertView.updateShowTimeout), userInfo: nil, repeats: true)
        }
        
        // Animate in the alert view
        self.showAnimation(animationStyle)
        
        // Chainable objects
        return SCLAlertViewResponder(alertview: self)
    }
    
    // Show animation in the alert view
    fileprivate func showAnimation(_ animationStyle: SCLAnimationStyle = .topToBottom, animationStartOffset: CGFloat = -400.0, boundingAnimationOffset: CGFloat = 15.0, animationDuration: TimeInterval = 0.2) {
        
        let rv = UIApplication.shared.keyWindow! as UIWindow
        var animationStartOrigin = self.baseView.frame.origin
        var animationCenter : CGPoint = rv.center
        
        switch animationStyle {
            
        case .noAnimation:
            self.view.alpha = 1.0
            return;
            
        case .topToBottom:
            animationStartOrigin = CGPoint(x: animationStartOrigin.x, y: self.baseView.frame.origin.y + animationStartOffset)
            animationCenter = CGPoint(x: animationCenter.x, y: animationCenter.y + boundingAnimationOffset)
            
        case .bottomToTop:
            animationStartOrigin = CGPoint(x: animationStartOrigin.x, y: self.baseView.frame.origin.y - animationStartOffset)
            animationCenter = CGPoint(x: animationCenter.x, y: animationCenter.y - boundingAnimationOffset)
            
        case .leftToRight:
            animationStartOrigin = CGPoint(x: self.baseView.frame.origin.x + animationStartOffset, y: animationStartOrigin.y)
            animationCenter = CGPoint(x: animationCenter.x + boundingAnimationOffset, y: animationCenter.y)
            
        case .rightToLeft:
            animationStartOrigin = CGPoint(x: self.baseView.frame.origin.x - animationStartOffset, y: animationStartOrigin.y)
            animationCenter = CGPoint(x: animationCenter.x - boundingAnimationOffset, y: animationCenter.y)
        }
        
        self.baseView.frame.origin = animationStartOrigin
        
        if self.appearance.dynamicAnimatorActive {
            UIView.animate(withDuration: animationDuration, animations: { 
                self.view.alpha = 1.0
            })
            self.animate(item: self.baseView, center: rv.center)
        } else {
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.alpha = 1.0
                self.baseView.center = animationCenter
            }, completion: { finished in
                UIView.animate(withDuration: animationDuration, animations: {
                    self.view.alpha = 1.0
                    self.baseView.center = rv.center
                })
            })
        }
    }
    
    // DynamicAnimator function
    var animator : UIDynamicAnimator?
    var snapBehavior : UISnapBehavior?
    
    fileprivate func animate(item : UIView , center: CGPoint) {
        
        if let snapBehavior = self.snapBehavior {
            self.animator?.removeBehavior(snapBehavior)
        }
        
        self.animator = UIDynamicAnimator.init(referenceView: self.view)
        let tempSnapBehavior  =  UISnapBehavior.init(item: item, snapTo: center)
        self.animator?.addBehavior(tempSnapBehavior)
        self.snapBehavior? = tempSnapBehavior
    }
    
    //
    @objc open func updateShowTimeout() {
        
        guard let timeout = self.timeout else {
            return
        }
        
        self.timeout?.value = timeout.value.advanced(by: -1)
        
        for btn in buttons {
            guard let showTimeout = btn.showTimeout else {
                continue
            }
            
            let timeoutStr: String = showTimeout.prefix + String(Int(timeout.value)) + showTimeout.suffix
            let txt = String(btn.initialTitle) + " " + timeoutStr
            btn.setTitle(txt, for: UIControlState())
            
        }
        
    }
    
    // Close SCLAlertView
    @objc open func hideView() {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
        }, completion: { finished in
            
            // Stop timeoutTimer so alertView does not attempt to hide itself and fire it's dimiss block a second time when close button is tapped
            self.timeoutTimer?.invalidate()
            
            // Stop showTimeoutTimer
            self.showTimeoutTimer?.invalidate()
            
            if let dismissBlock = self.dismissBlock {
                // Call completion handler when the alert is dismissed
                dismissBlock()
            }
            
            // This is necessary for SCLAlertView to be de-initialized, preventing a strong reference cycle with the viewcontroller calling SCLAlertView.
            for button in self.buttons {
                button.action = nil
                button.target = nil
                button.selector = nil
            }
            
            self.view.removeFromSuperview()
            self.selfReference = nil
        })
    }
    
    @objc open func hideViewTimeout() {
        self.timeout?.action()
        self.hideView()
    }
    
    //Return true if a SCLAlertView is already being shown, false otherwise
    open func isShowing() -> Bool {
        if let subviews = UIApplication.shared.keyWindow?.subviews {
            for view in subviews {
                if view.tag == uniqueTag && view.accessibilityIdentifier == uniqueAccessibilityIdentifier {
                    return true
                }
            }
        }
        return false
    }
}

// Helper function to convert from RGB to UIColor
public func UIColorFromRGB(_ rgbValue: UInt) -> UIColor {
    return UIColor(
        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
        alpha: CGFloat(1.0)
    )
}

// MARK: Comparable
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}
