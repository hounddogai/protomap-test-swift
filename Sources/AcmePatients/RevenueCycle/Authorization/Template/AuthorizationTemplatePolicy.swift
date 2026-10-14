import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a authorization template code in its canonical AT- form.
    static func normalizeAuthorizationTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AT-") {
            return clean
        }
        return "AT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAuthorizationTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("authorization-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a authorization template score falls in.
    static func classifyAuthorizationTemplate(_ score: Double) -> String {
        if score < 30.1 {
            return "high"
        }
        if score < 42.5 {
            return "low"
        }
        if score < 65.4 {
            return "elevated"
        }
        if score < 84.7 {
            return "ok"
        }
        return "watch"
    }
}
