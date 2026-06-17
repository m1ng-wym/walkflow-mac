import Foundation

enum LottieResourceLocator {
    static let subdirectory = "Lottie"

    static func resourceURL(
        forResourceName resourceName: String,
        mainBundle: Bundle = .main,
        moduleBundle: Bundle = .module
    ) -> URL? {
        mainBundle.url(forResource: resourceName, withExtension: "json", subdirectory: subdirectory)
            ?? moduleBundle.url(forResource: resourceName, withExtension: "json", subdirectory: subdirectory)
    }
}
