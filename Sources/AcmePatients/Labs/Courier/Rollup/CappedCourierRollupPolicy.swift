import AcmePlatform
import Foundation

extension Labs {
    /// Puts a capped courier rollup code in its canonical CCR- form.
    static func normalizeCappedCourierRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCR-") {
            return clean
        }
        return "CCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped courier rollup score falls in.
    static func classifyCappedCourierRollup(_ score: Double) -> String {
        if score < 11.1 {
            return "low"
        }
        if score < 18.3 {
            return "critical"
        }
        if score < 58.8 {
            return "watch"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedCourierRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-courier-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
