import Foundation

public enum ControlAction: Equatable, Sendable {
    case none
    case scrollUp(step: ScrollStep)
    case scrollDown(step: ScrollStep)
    case pressRightCommand
    case stopContinuousScroll
}

public enum ScrollStep: Equatable, Sendable {
    case single
    case continuous
}
