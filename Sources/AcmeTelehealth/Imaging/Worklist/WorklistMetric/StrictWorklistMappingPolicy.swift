import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 50371.0, in order.
    static func strictWorklistMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50371.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictWorklistMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a strict worklist mapping code in its canonical SWM- form.
    static func normalizeStrictWorklistMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWM-") {
            return clean
        }
        return "SWM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictWorklistMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-worklist-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
