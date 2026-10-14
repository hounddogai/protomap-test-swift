import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered rounding adjustment calculation.
    protocol TieredRoundingAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: TieredRoundingAdjustment, value: Double) -> Double
    }

    final class MinimumTieredRoundingAdjustmentAdjuster: TieredRoundingAdjustmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredRoundingAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentTieredRoundingAdjustmentAdjuster: TieredRoundingAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredRoundingAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRoundingAdjustmentBudgetOffsetAdjuster: TieredRoundingAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: TieredRoundingAdjustment, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the tiered rounding adjustment steps in order and keeps a trace of each.
    final class TieredRoundingAdjustmentEngine {
        var steps: [any TieredRoundingAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredRoundingAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredRoundingAdjustment) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredRoundingAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [TieredRoundingAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredRoundingAdjustmentEngine() -> TieredRoundingAdjustmentEngine {
        return TieredRoundingAdjustmentEngine(
            steps: [
                MinimumTieredRoundingAdjustmentAdjuster(minimum: 15.3),
                PercentTieredRoundingAdjustmentAdjuster(percent: 4.6),
                TieredRoundingAdjustmentBudgetOffsetAdjuster(weight: 1.51),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 67544.8
        )
    }
}
