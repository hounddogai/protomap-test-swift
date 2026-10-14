import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a manual proxy schedule score falls in.
    static func classifyManualProxySchedule(_ score: Double) -> String {
        if score < 54.5 {
            return "low"
        }
        if score < 73.0 {
            return "ok"
        }
        if score < 80.5 {
            return "critical"
        }
        if score < 89.8 {
            return "high"
        }
        return "minimal"
    }

    static func manualProxyScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeManualProxyScheduleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 4954.0, in order.
    static func manualProxyScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4954.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
