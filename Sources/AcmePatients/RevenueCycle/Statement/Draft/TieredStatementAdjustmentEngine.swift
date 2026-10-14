import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the tiered statement adjustment calculation.
    protocol TieredStatementAdjustmentStep {
        func describe() -> String
        func adjust(_ item: TieredStatementAdjustment, value: Double) -> Double
    }

    final class RoundingTieredStatementAdjustmentAdjuster: TieredStatementAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredStatementAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStatementAdjustmentDosageMgOffsetAdjuster: TieredStatementAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: TieredStatementAdjustment, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class LabelTieredStatementAdjustmentAdjuster: TieredStatementAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredStatementAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered statement adjustment steps in order and keeps a trace of each.
    final class TieredStatementAdjustmentEngine {
        var steps: [any TieredStatementAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredStatementAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: TieredStatementAdjustment) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredStatementAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [TieredStatementAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultTieredStatementAdjustmentEngine() -> TieredStatementAdjustmentEngine {
        return TieredStatementAdjustmentEngine(
            steps: [
                RoundingTieredStatementAdjustmentAdjuster(step: 0.5),
                TieredStatementAdjustmentDosageMgOffsetAdjuster(weight: 1.87),
                LabelTieredStatementAdjustmentAdjuster(factors: ["north": 1.38, "west": 0.88]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 3139.1
        )
    }
}
