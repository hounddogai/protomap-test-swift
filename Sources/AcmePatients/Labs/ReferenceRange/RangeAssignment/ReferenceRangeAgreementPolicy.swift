import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 82711.0, in order.
    static func referenceRangeAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82711.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func referenceRangeAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a reference range agreement score falls in.
    static func classifyReferenceRangeAgreement(_ score: Double) -> String {
        if score < 2.3 {
            return "high"
        }
        if score < 61.8 {
            return "low"
        }
        if score < 65.4 {
            return "ok"
        }
        return "minimal"
    }
}
