import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered recall metric calculation.
    protocol TieredRecallMetricFactor {
        func describe() -> String
        func adjust(_ item: TieredRecallMetric, value: Double) -> Double
    }

    final class MinimumTieredRecallMetricAdjuster: TieredRecallMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRecallMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredRecallMetricAdjuster: TieredRecallMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredRecallMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredRecallMetricAdjuster: TieredRecallMetricFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredRecallMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentTieredRecallMetricAdjuster: TieredRecallMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: TieredRecallMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentTieredRecallMetricAdjuster: TieredRecallMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRecallMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered recall metric steps in order and keeps a trace of each.
    final class TieredRecallMetricEngine {
        var steps: [any TieredRecallMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRecallMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredRecallMetric) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRecallMetricFactor = steps[index]
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

        func evaluateAll(_ items: [TieredRecallMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredRecallMetricEngine() -> TieredRecallMetricEngine {
        return TieredRecallMetricEngine(
            steps: [
                MinimumTieredRecallMetricAdjuster(minimum: 33.1),
                CapTieredRecallMetricAdjuster(cap: 33795.0),
                RoundingTieredRecallMetricAdjuster(step: 0.05),
                SegmentTieredRecallMetricAdjuster(factors: ["online": 1.35, "retail": 1.26, "central": 0.87]),
                PercentTieredRecallMetricAdjuster(percent: -2.2),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 32394.6
        )
    }
}
