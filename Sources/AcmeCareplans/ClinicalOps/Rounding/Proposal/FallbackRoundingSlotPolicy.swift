import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackRoundingSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-rounding-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a fallback rounding slot code in its canonical FRS- form.
    static func normalizeFallbackRoundingSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FRS-") {
            return clean
        }
        return "FRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
