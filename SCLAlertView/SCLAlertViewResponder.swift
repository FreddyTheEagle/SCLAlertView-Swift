open class SCLAlertViewResponder {
    let alertview: SCLAlertView
    
    public init(alertview: SCLAlertView) {
        self.alertview = alertview
    }
    
    open func setTitle(_ title: String) {
        self.alertview.labelTitle.text = title
    }
    
    open func setSubTitle(_ subTitle: String) {
        self.alertview.viewText.text = subTitle
    }
    
    open func close() {
        self.alertview.hideView()
    }
    
    open func setDismissBlock(_ dismissBlock: @escaping DismissBlock) {
        self.alertview.dismissBlock = dismissBlock
    }
}
