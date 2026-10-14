import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding metric calculation.
    protocol RoundingMetricModifier {
        func describe() -> String
        func adjust(_ item: RoundingMetric, value: Double) -> Double
    }

    final class RoundingRoundingMetricAdjuster: RoundingMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RoundingMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRoundingMetricAdjuster: RoundingMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRoundingMetricAdjuster: RoundingMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRoundingMetricAdjuster: RoundingMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RoundingMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rounding metric steps in order and keeps a trace of each.
    final class RoundingMetricEngine {
        var steps: [any RoundingMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RoundingMetric) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RoundingMetricModifier = steps[index]
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

        func evaluateAll(_ items: [RoundingMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRoundingMetricEngine() -> RoundingMetricEngine {
        return RoundingMetricEngine(
            steps: [
                RoundingRoundingMetricAdjuster(step: 0.5),
                CapRoundingMetricAdjuster(cap: 11073.0),
                PercentRoundingMetricAdjuster(percent: 20.3),
                NameRoundingMetricAdjuster(factors: ["west": 1.06, "central": 0.97, "south": 1.03]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 55603.6
        )
    }
}
