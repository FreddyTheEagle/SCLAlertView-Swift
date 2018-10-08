public enum SCLAlertViewType {
    case success, error, notice, warning, info, edit, wait, question
    
    public var defaultColor: UInt {
        switch self {
        case .success: return 0x22B573
        case .error: return 0xC1272D
        case .notice: return 0x727375
        case .warning: return 0xFFD110
        case .info: return 0x2866BF
        case .edit: return 0xA429FF
        case .wait: return 0xD62DA5
        case .question: return 0x727375
        }
    }
    
    public var image: UIImage? {
        switch self {
        case .success: return SCLAlertViewStyleKit.imageOfCheckmark
        case .error: return SCLAlertViewStyleKit.imageOfCross
        case .notice: return SCLAlertViewStyleKit.imageOfNotice
        case .warning: return SCLAlertViewStyleKit.imageOfWarning
        case .info: return SCLAlertViewStyleKit.imageOfInfo
        case .edit: return SCLAlertViewStyleKit.imageOfEdit
        case .wait: return SCLAlertViewStyleKit.imageOfInfo
        case .question: return SCLAlertViewStyleKit.imageOfQuestion
        }
    }
    
    public var colorTextButton: UInt {
        switch self {
        case .success, .error, .notice, .info, .wait, .edit, .question: return 0xFFFFFF
        case .warning: return 0x000000
        }
    }
}
