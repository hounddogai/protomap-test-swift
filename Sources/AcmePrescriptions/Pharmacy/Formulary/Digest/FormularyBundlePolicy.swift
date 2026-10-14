import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a formulary bundle code in its canonical FB- form.
    static func normalizeFormularyBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FB-") {
            return clean
        }
        return "FB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFormularyBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("formulary-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a formulary bundle score falls in.
    static func classifyFormularyBundle(_ score: Double) -> String {
        if score < 29.5 {
            return "critical"
        }
        if score < 47.9 {
            return "elevated"
        }
        if score < 93.6 {
            return "medium"
        }
        if score < 97.5 {
            return "low"
        }
        return "watch"
    }

    static func formularyBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
