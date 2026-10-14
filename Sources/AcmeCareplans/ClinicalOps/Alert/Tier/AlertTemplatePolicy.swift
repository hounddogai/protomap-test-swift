import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a alert template score falls in.
    static func classifyAlertTemplate(_ score: Double) -> String {
        if score < 12.7 {
            return "medium"
        }
        if score < 34.9 {
            return "minimal"
        }
        if score < 61.1 {
            return "high"
        }
        if score < 69.7 {
            return "watch"
        }
        return "critical"
    }

    /// Puts a alert template code in its canonical AT- form.
    static func normalizeAlertTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AT-") {
            return clean
        }
        return "AT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func alertTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAlertTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("alert-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
