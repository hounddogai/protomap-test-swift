import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a care protocol exception score falls in.
    static func classifyCareProtocolException(_ score: Double) -> String {
        if score < 9.6 {
            return "watch"
        }
        if score < 67.6 {
            return "low"
        }
        if score < 89.9 {
            return "ok"
        }
        if score < 99.5 {
            return "minimal"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 61583.0, in order.
    static func careProtocolExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61583.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
