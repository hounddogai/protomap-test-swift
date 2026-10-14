import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultInteractionSchedule() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-interaction-schedule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a default interaction schedule code in its canonical DIS- form.
    static func normalizeDefaultInteractionScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DIS-") {
            return clean
        }
        return "DIS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultInteractionScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 27714.0, in order.
    static func defaultInteractionScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27714.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
