import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a adaptive network snapshot code in its canonical ANS- form.
    static func normalizeAdaptiveNetworkSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ANS-") {
            return clean
        }
        return "ANS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 36290.0, in order.
    static func adaptiveNetworkSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36290.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveNetworkSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
