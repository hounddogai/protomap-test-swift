import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedIsolationScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-isolation-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a capped isolation score code in its canonical CIS- form.
    static func normalizeCappedIsolationScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CIS-") {
            return clean
        }
        return "CIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a capped isolation score score falls in.
    static func classifyCappedIsolationScore(_ score: Double) -> String {
        if score < 17.9 {
            return "elevated"
        }
        if score < 53.8 {
            return "ok"
        }
        if score < 68.6 {
            return "watch"
        }
        return "critical"
    }
}
