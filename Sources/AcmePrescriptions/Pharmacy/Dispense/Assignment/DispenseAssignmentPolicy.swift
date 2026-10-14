import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a dispense assignment code in its canonical DA- form.
    static func normalizeDispenseAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DA-") {
            return clean
        }
        return "DA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dispenseAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 5214.0, in order.
    static func dispenseAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5214.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
