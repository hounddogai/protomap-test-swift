import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 75287.0, in order.
    static func priorityBundleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75287.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func priorityBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a priority bundle code in its canonical PB- form.
    static func normalizePriorityBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PB-") {
            return clean
        }
        return "PB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
