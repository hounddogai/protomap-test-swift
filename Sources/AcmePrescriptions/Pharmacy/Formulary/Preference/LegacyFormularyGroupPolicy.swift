import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a legacy formulary group code in its canonical LFG- form.
    static func normalizeLegacyFormularyGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LFG-") {
            return clean
        }
        return "LFG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a legacy formulary group score falls in.
    static func classifyLegacyFormularyGroup(_ score: Double) -> String {
        if score < 9.6 {
            return "minimal"
        }
        if score < 63.3 {
            return "elevated"
        }
        if score < 70.6 {
            return "critical"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyFormularyGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-formulary-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
