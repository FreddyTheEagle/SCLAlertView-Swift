open class SCLButton: UIButton {
    var actionType = SCLActionType.none
    var target: AnyObject!
    var selector: Selector!
    var action: (()->Void)!
    var customBackgroundColor: UIColor?
    var customTextColor: UIColor?
    var initialTitle: String!
    var showTimeout: ShowTimeoutConfiguration?
    
    public struct ShowTimeoutConfiguration {
        let prefix: String
        let suffix: String
        
        public init(prefix: String = "", suffix: String = "") {
            self.prefix = prefix
            self.suffix = suffix
        }
    }
    
    public init() {
        super.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override public init (frame: CGRect) {
        super.init(frame: frame)
    }
}
