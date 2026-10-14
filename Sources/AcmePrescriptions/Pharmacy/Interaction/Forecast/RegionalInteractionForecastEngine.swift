import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional interaction forecast calculation.
    protocol RegionalInteractionForecastAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalInteractionForecast, value: Double) -> Double
    }

    final class CapRegionalInteractionForecastAdjuster: RegionalInteractionForecastAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalInteractionForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalInteractionForecastAdjuster: RegionalInteractionForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalInteractionForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalInteractionForecastAdjuster: RegionalInteractionForecastAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalInteractionForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRegionalInteractionForecastAdjuster: RegionalInteractionForecastAdjuster {
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

        func adjust(_ item: RegionalInteractionForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the regional interaction forecast steps in order and keeps a trace of each.
    final class RegionalInteractionForecastEngine {
        var steps: [any RegionalInteractionForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalInteractionForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalInteractionForecast) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalInteractionForecastAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RegionalInteractionForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalInteractionForecastEngine(_ flags: Kit.Flags.Registry) -> RegionalInteractionForecastEngine {
        return RegionalInteractionForecastEngine(
            steps: [
                CapRegionalInteractionForecastAdjuster(cap: 41991.0),
                PercentRegionalInteractionForecastAdjuster(percent: -15.5),
                RoundingRegionalInteractionForecastAdjuster(step: 0.1),
                FlaggedRegionalInteractionForecastAdjuster(
                    flags: flags,
                    flag: "regional-interaction-forecast-global",
                    percent: 1.7
                ),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 71623.3
        )
    }
}
