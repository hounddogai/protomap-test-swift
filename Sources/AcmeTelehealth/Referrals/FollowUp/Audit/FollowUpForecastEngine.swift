import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up forecast calculation.
    protocol FollowUpForecastFactor {
        func describe() -> String
        func adjust(_ item: FollowUpForecast, value: Double) -> Double
    }

    final class FlaggedFollowUpForecastAdjuster: FollowUpForecastFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: FollowUpForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFollowUpForecastAdjuster: FollowUpForecastFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFollowUpForecastAdjuster: FollowUpForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the follow up forecast steps in order and keeps a trace of each.
    final class FollowUpForecastEngine {
        var steps: [any FollowUpForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpForecast) -> Double {
            var current = item.weightedVolume()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [FollowUpForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpForecastEngine(_ flags: Kit.Flags.Registry) -> FollowUpForecastEngine {
        return FollowUpForecastEngine(
            steps: [
                FlaggedFollowUpForecastAdjuster(flags: flags, flag: "follow-up-forecast-weighted", percent: 9.1),
                RoundingFollowUpForecastAdjuster(step: 1.0),
                TieredFollowUpForecastAdjuster(bounds: [626.0, 9607.0], rates: [0.88, 0.93]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 13417.1
        )
    }
}
