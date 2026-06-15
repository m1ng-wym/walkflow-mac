import Foundation

public enum PermissionKind: String, CaseIterable, Sendable {
    case camera
    case accessibility
    case inputMonitoring
}

public enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
    case notDetermined
    case notRequired
}

public struct PermissionSnapshot: Equatable, Sendable {
    public var camera: PermissionStatus
    public var accessibility: PermissionStatus
    public var inputMonitoring: PermissionStatus

    public init(camera: PermissionStatus, accessibility: PermissionStatus, inputMonitoring: PermissionStatus) {
        self.camera = camera
        self.accessibility = accessibility
        self.inputMonitoring = inputMonitoring
    }

    public var canControl: Bool {
        camera == .granted && accessibility == .granted
    }
}
