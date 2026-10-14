import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a legacy accession adjustment score falls in.
    static func classifyLegacyAccessionAdjustment(_ score: Double) -> String {
        if score < 20.0 {
            return "medium"
        }
        if score < 47.8 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a legacy accession adjustment code in its canonical LAA- form.
    static func normalizeLegacyAccessionAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAA-") {
            return clean
        }
        return "LAA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyAccessionAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-accession-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyAccessionAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
