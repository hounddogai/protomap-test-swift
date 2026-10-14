import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession forecast calculation.
    protocol AccessionForecastModifier {
        func describe() -> String
        func adjust(_ item: AccessionForecast, value: Double) -> Double
    }

    final class MinimumAccessionForecastAdjuster: AccessionForecastModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AccessionForecastDiscountOffsetAdjuster: AccessionForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: AccessionForecast, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingAccessionForecastAdjuster: AccessionForecastModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAccessionForecastAdjuster: AccessionForecastModifier {
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

        func adjust(_ item: AccessionForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession forecast steps in order and keeps a trace of each.
    final class AccessionForecastEngine {
        var steps: [any AccessionForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AccessionForecast) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionForecastModifier = steps[index]
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

        func evaluateAll(_ items: [AccessionForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAccessionForecastEngine(_ flags: Kit.Flags.Registry) -> AccessionForecastEngine {
        return AccessionForecastEngine(
            steps: [
                MinimumAccessionForecastAdjuster(minimum: 46.6),
                AccessionForecastDiscountOffsetAdjuster(weight: 0.59),
                RoundingAccessionForecastAdjuster(step: 0.05),
                FlaggedAccessionForecastAdjuster(flags: flags, flag: "accession-forecast-scheduled", percent: -0.8),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 49367.5
        )
    }
}
