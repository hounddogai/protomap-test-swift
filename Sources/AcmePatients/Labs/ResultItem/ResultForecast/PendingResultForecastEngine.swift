import AcmePlatform
import Foundation

extension Labs {
    /// One step of the pending result forecast calculation.
    protocol PendingResultForecastStep {
        func describe() -> String
        func adjust(_ item: PendingResultForecast, value: Double) -> Double
    }

    final class RoundingPendingResultForecastAdjuster: PendingResultForecastStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingResultForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentPendingResultForecastAdjuster: PendingResultForecastStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingResultForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingResultForecastAdjuster: PendingResultForecastStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingResultForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingResultForecastAdjuster: PendingResultForecastStep {
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

        func adjust(_ item: PendingResultForecast, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelPendingResultForecastAdjuster: PendingResultForecastStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingResultForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the pending result forecast steps in order and keeps a trace of each.
    final class PendingResultForecastEngine {
        var steps: [any PendingResultForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingResultForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingResultForecast) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingResultForecastStep = steps[index]
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

        func evaluateAll(_ items: [PendingResultForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingResultForecastEngine(_ flags: Kit.Flags.Registry) -> PendingResultForecastEngine {
        return PendingResultForecastEngine(
            steps: [
                RoundingPendingResultForecastAdjuster(step: 1.0),
                PercentPendingResultForecastAdjuster(percent: -13.8),
                CapPendingResultForecastAdjuster(cap: 46140.0),
                FlaggedPendingResultForecastAdjuster(
                    flags: flags,
                    flag: "pending-result-forecast-strict",
                    percent: 8.6
                ),
                LabelPendingResultForecastAdjuster(factors: ["north": 0.83, "retail": 1.01]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 65891.3
        )
    }
}
