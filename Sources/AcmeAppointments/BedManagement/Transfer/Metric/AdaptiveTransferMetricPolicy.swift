import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a adaptive transfer metric code in its canonical ATM- form.
    static func normalizeAdaptiveTransferMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ATM-") {
            return clean
        }
        return "ATM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveTransferMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-transfer-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func adaptiveTransferMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 57524.0, in order.
    static func adaptiveTransferMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57524.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
