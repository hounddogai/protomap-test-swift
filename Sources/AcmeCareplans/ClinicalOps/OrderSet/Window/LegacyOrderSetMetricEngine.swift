import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy order set metric calculation.
    protocol LegacyOrderSetMetricStep {
        func describe() -> String
        func adjust(_ item: LegacyOrderSetMetric, value: Double) -> Double
    }

    final class LegacyOrderSetMetricStartsAtOffsetAdjuster: LegacyOrderSetMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: LegacyOrderSetMetric, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class RoundingLegacyOrderSetMetricAdjuster: LegacyOrderSetMetricStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyOrderSetMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLegacyOrderSetMetricAdjuster: LegacyOrderSetMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyOrderSetMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLegacyOrderSetMetricAdjuster: LegacyOrderSetMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyOrderSetMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyOrderSetMetricAdjuster: LegacyOrderSetMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyOrderSetMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy order set metric steps in order and keeps a trace of each.
    final class LegacyOrderSetMetricEngine {
        var steps: [any LegacyOrderSetMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyOrderSetMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyOrderSetMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyOrderSetMetricStep = steps[index]
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

        func evaluateAll(_ items: [LegacyOrderSetMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyOrderSetMetricEngine() -> LegacyOrderSetMetricEngine {
        return LegacyOrderSetMetricEngine(
            steps: [
                LegacyOrderSetMetricStartsAtOffsetAdjuster(weight: 0.88),
                RoundingLegacyOrderSetMetricAdjuster(step: 0.25),
                MinimumLegacyOrderSetMetricAdjuster(minimum: 32.6),
                PercentLegacyOrderSetMetricAdjuster(percent: 14.0),
                CapLegacyOrderSetMetricAdjuster(cap: 14999.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 43199.9
        )
    }
}
