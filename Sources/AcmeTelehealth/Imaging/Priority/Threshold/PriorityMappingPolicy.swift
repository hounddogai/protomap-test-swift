import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a priority mapping code in its canonical PM- form.
    static func normalizePriorityMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PM-") {
            return clean
        }
        return "PM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func priorityMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 17225.0, in order.
    static func priorityMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17225.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
