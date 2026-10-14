import AcmePlatform
import Foundation

extension Labs {
    /// One step of the capped accession adjustment calculation.
    protocol CappedAccessionAdjustmentStep {
        func describe() -> String
        func adjust(_ item: CappedAccessionAdjustment, value: Double) -> Double
    }

    final class CappedAccessionAdjustmentAmountOffsetAdjuster: CappedAccessionAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CappedAccessionAdjustment, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class LabelCappedAccessionAdjustmentAdjuster: CappedAccessionAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedAccessionAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedAccessionAdjustmentAdjuster: CappedAccessionAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedAccessionAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped accession adjustment steps in order and keeps a trace of each.
    final class CappedAccessionAdjustmentEngine {
        var steps: [any CappedAccessionAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedAccessionAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedAccessionAdjustment) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedAccessionAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [CappedAccessionAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedAccessionAdjustmentEngine() -> CappedAccessionAdjustmentEngine {
        return CappedAccessionAdjustmentEngine(
            steps: [
                CappedAccessionAdjustmentAmountOffsetAdjuster(weight: 0.23),
                LabelCappedAccessionAdjustmentAdjuster(factors: ["central": 1.07]),
                PercentCappedAccessionAdjustmentAdjuster(percent: -17.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 26156.5
        )
    }
}
