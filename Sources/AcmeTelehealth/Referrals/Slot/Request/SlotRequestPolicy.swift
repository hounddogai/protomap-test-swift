import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot request code in its canonical SR- form.
    static func normalizeSlotRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SR-") {
            return clean
        }
        return "SR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func slotRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func slotRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
