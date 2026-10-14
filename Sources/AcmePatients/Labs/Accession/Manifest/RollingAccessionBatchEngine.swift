import AcmePlatform
import Foundation

extension Labs {
    /// One step of the rolling accession batch calculation.
    protocol RollingAccessionBatchModifier {
        func describe() -> String
        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double
    }

    final class PercentRollingAccessionBatchAdjuster: RollingAccessionBatchModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingAccessionBatchAdjuster: RollingAccessionBatchModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingAccessionBatchMarginOffsetAdjuster: RollingAccessionBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class TieredRollingAccessionBatchAdjuster: RollingAccessionBatchModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentRollingAccessionBatchAdjuster: RollingAccessionBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingAccessionBatchAdjuster: RollingAccessionBatchModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingAccessionBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rolling accession batch steps in order and keeps a trace of each.
    final class RollingAccessionBatchEngine {
        var steps: [any RollingAccessionBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingAccessionBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingAccessionBatch) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingAccessionBatchModifier = steps[index]
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

        func evaluateAll(_ items: [RollingAccessionBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingAccessionBatchEngine() -> RollingAccessionBatchEngine {
        return RollingAccessionBatchEngine(
            steps: [
                PercentRollingAccessionBatchAdjuster(percent: 6.1),
                RoundingRollingAccessionBatchAdjuster(step: 0.5),
                RollingAccessionBatchMarginOffsetAdjuster(weight: 0.95),
                TieredRollingAccessionBatchAdjuster(bounds: [5654.0, 7144.0], rates: [1.04, 0.92]),
                SegmentRollingAccessionBatchAdjuster(factors: ["retail": 1.03, "west": 0.91, "east": 1.38]),
                MinimumRollingAccessionBatchAdjuster(minimum: 47.1),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 88527.2
        )
    }
}
