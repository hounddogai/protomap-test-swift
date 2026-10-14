import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a global slot adjustment code in its canonical GSA- form.
    static func normalizeGlobalSlotAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSA-") {
            return clean
        }
        return "GSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalSlotAdjustment() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-slot-adjustment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
