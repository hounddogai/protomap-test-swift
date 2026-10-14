import AcmePlatform
import Foundation

extension Labs {
    /// Puts a adaptive result bundle code in its canonical ARB- form.
    static func normalizeAdaptiveResultBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARB-") {
            return clean
        }
        return "ARB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveResultBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveResultBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-result-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a adaptive result bundle score falls in.
    static func classifyAdaptiveResultBundle(_ score: Double) -> String {
        if score < 17.5 {
            return "ok"
        }
        if score < 24.8 {
            return "watch"
        }
        if score < 55.1 {
            return "elevated"
        }
        return "low"
    }
}
