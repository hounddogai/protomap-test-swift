import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a pending recall allocation code in its canonical PRA- form.
    static func normalizePendingRecallAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRA-") {
            return clean
        }
        return "PRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingRecallAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-recall-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func pendingRecallAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
