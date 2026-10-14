import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 70481.0, in order.
    static func strictBedBoardForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70481.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeStrictBedBoardForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a strict bed board forecast score falls in.
    static func classifyStrictBedBoardForecast(_ score: Double) -> String {
        if score < 8.5 {
            return "minimal"
        }
        if score < 74.3 {
            return "critical"
        }
        if score < 74.6 {
            return "ok"
        }
        return "watch"
    }

    static func strictBedBoardForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
