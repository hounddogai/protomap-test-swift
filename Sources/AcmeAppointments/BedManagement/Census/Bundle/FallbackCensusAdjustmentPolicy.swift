import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCensusAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-census-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback census adjustment code in its canonical FCA- form.
    static func normalizeFallbackCensusAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCA-") {
            return clean
        }
        return "FCA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
