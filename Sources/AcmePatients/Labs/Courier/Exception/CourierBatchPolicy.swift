import AcmePlatform
import Foundation

extension Labs {
    static func courierBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCourierBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("courier-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a courier batch code in its canonical CB- form.
    static func normalizeCourierBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CB-") {
            return clean
        }
        return "CB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 22769.0, in order.
    static func courierBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22769.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
