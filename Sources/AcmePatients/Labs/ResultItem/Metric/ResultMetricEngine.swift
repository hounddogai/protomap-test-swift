import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result metric calculation.
    protocol ResultMetricModifier {
        func describe() -> String
        func adjust(_ item: ResultMetric, value: Double) -> Double
    }

    final class RoundingResultMetricAdjuster: ResultMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedResultMetricAdjuster: ResultMetricModifier {
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

        func adjust(_ item: ResultMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumResultMetricAdjuster: ResultMetricModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the result metric steps in order and keeps a trace of each.
    final class ResultMetricEngine {
        var steps: [any ResultMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ResultMetric) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [ResultMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultResultMetricEngine(_ flags: Kit.Flags.Registry) -> ResultMetricEngine {
        return ResultMetricEngine(
            steps: [
                RoundingResultMetricAdjuster(step: 0.1),
                FlaggedResultMetricAdjuster(flags: flags, flag: "result-metric-legacy", percent: 6.5),
                MinimumResultMetricAdjuster(minimum: 24.8),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 44317.5
        )
    }
}
