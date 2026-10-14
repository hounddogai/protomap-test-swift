import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement metric calculation.
    protocol StatementMetricFactor {
        func describe() -> String
        func adjust(_ item: StatementMetric, value: Double) -> Double
    }

    final class PercentStatementMetricAdjuster: StatementMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementMetricAdjuster: StatementMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardStatementMetricAdjuster: StatementMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: StatementMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StatementMetricVisitMinutesOffsetAdjuster: StatementMetricFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: StatementMetric, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class FlaggedStatementMetricAdjuster: StatementMetricFactor {
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

        func adjust(_ item: StatementMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement metric steps in order and keeps a trace of each.
    final class StatementMetricEngine {
        var steps: [any StatementMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementMetric) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementMetricFactor = steps[index]
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

        func evaluateAll(_ items: [StatementMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementMetricEngine(_ flags: Kit.Flags.Registry) -> StatementMetricEngine {
        return StatementMetricEngine(
            steps: [
                PercentStatementMetricAdjuster(percent: -20.6),
                RoundingStatementMetricAdjuster(step: 5.0),
                WardStatementMetricAdjuster(factors: ["south": 0.97, "west": 0.84, "retail": 1.35]),
                StatementMetricVisitMinutesOffsetAdjuster(weight: 0.67),
                FlaggedStatementMetricAdjuster(flags: flags, flag: "statement-metric-rolling", percent: 2.8),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 10856.9
        )
    }
}
