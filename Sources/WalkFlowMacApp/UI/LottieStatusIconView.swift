import AppKit
import Lottie
import WalkFlowCore

final class LottieStatusIconView: NSView {
    private let animationView = LottieAnimationView(frame: .zero)
    private let animationLoader: (URL) -> LottieAnimation?
    private(set) var currentIcon: HUDIcon = .none
    var hasLoadedAnimation: Bool { animationView.animation != nil }
    var isAnimationVisible: Bool { !animationView.isHidden }
    var currentLoopMode: LottieLoopMode { animationView.loopMode }

    init(frame frameRect: NSRect, animationLoader: @escaping (URL) -> LottieAnimation? = { LottieAnimation.filepath($0.path) }) {
        self.animationLoader = animationLoader
        super.init(frame: frameRect)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.topAnchor.constraint(equalTo: topAnchor),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        clearAnimation()
    }

    required init?(coder: NSCoder) {
        nil
    }

    func show(icon: HUDIcon) {
        guard icon != currentIcon else {
            return
        }

        guard let resourceURL = Self.resourceURL(for: icon) else {
            currentIcon = .none
            clearAnimation()
            return
        }

        guard let animation = animationLoader(resourceURL) else {
            currentIcon = .none
            clearAnimation()
            return
        }

        currentIcon = icon
        animationView.animation = animation
        animationView.isHidden = false

        switch icon {
        case .alertTriangle, .infinity, .arrowUp, .arrowDown, .dribbble:
            animationView.loopMode = .loop
            animationView.currentProgress = 0
            animationView.play()
        case .unlockOnce:
            animationView.loopMode = .playOnce
            animationView.play(fromProgress: 0, toProgress: 1, loopMode: .playOnce)
        case .lock:
            animationView.stop()
            animationView.loopMode = .playOnce
            animationView.currentProgress = 0
        case .none:
            clearAnimation()
        }
    }

    static func resourceName(for icon: HUDIcon) -> String? {
        switch icon {
        case .none:
            return nil
        case .alertTriangle:
            return "alertTriangle"
        case .infinity:
            return "infinity"
        case .arrowUp:
            return "arrowUp"
        case .arrowDown:
            return "arrowDown"
        case .dribbble:
            return "dribbble"
        case .lock, .unlockOnce:
            return "lock"
        }
    }

    static func resourceURL(for icon: HUDIcon) -> URL? {
        guard let resourceName = resourceName(for: icon) else {
            return nil
        }

        return LottieResourceLocator.resourceURL(forResourceName: resourceName)
    }

    private func clearAnimation() {
        animationView.stop()
        animationView.animation = nil
        animationView.currentProgress = 0
        animationView.isHidden = true
    }
}
