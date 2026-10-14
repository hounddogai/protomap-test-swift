import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveLanguageTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-language-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptiveLanguageTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a adaptive language template code in its canonical ALT- form.
    static func normalizeAdaptiveLanguageTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ALT-") {
            return clean
        }
        return "ALT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
