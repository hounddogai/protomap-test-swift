import AcmePlatform
import Foundation

extension Referrals {
    static func pendingSlotManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingSlotManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-slot-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a pending slot manifest code in its canonical PSM- form.
    static func normalizePendingSlotManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSM-") {
            return clean
        }
        return "PSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingSlotManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
