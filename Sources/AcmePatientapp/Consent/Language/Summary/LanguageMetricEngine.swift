import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language metric calculation.
    protocol LanguageMetricFactor {
        func describe() -> String
        func adjust(_ item: LanguageMetric, value: Double) -> Double
    }

    final class TieredLanguageMetricAdjuster: LanguageMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LanguageMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LanguageMetricAttemptsOffsetAdjuster: LanguageMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LanguageMetric, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingLanguageMetricAdjuster: LanguageMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLanguageMetricAdjuster: LanguageMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLanguageMetricAdjuster: LanguageMetricFactor {
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

        func adjust(_ item: LanguageMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language metric steps in order and keeps a trace of each.
    final class LanguageMetricEngine {
        var steps: [any LanguageMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageMetricFactor = steps[index]
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

        func evaluateAll(_ items: [LanguageMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageMetricEngine(_ flags: Kit.Flags.Registry) -> LanguageMetricEngine {
        return LanguageMetricEngine(
            steps: [
                TieredLanguageMetricAdjuster(bounds: [3426.0, 4289.0, 8966.0], rates: [0.86, 0.97, 0.88]),
                LanguageMetricAttemptsOffsetAdjuster(weight: 1.68),
                RoundingLanguageMetricAdjuster(step: 0.25),
                PercentLanguageMetricAdjuster(percent: -2.9),
                FlaggedLanguageMetricAdjuster(flags: flags, flag: "language-metric-primary", percent: 9.8),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 66758.3
        )
    }
}
