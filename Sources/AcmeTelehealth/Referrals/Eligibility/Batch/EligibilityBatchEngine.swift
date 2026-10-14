import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility batch calculation.
    protocol EligibilityBatchStep {
        func describe() -> String
        func adjust(_ item: EligibilityBatch, value: Double) -> Double
    }

    final class RoundingEligibilityBatchAdjuster: EligibilityBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class EligibilityBatchMarginOffsetAdjuster: EligibilityBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: EligibilityBatch, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class PercentEligibilityBatchAdjuster: EligibilityBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility batch steps in order and keeps a trace of each.
    final class EligibilityBatchEngine {
        var steps: [any EligibilityBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: EligibilityBatch) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [EligibilityBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultEligibilityBatchEngine() -> EligibilityBatchEngine {
        return EligibilityBatchEngine(
            steps: [
                RoundingEligibilityBatchAdjuster(step: 0.1),
                EligibilityBatchMarginOffsetAdjuster(weight: 1.95),
                PercentEligibilityBatchAdjuster(percent: -2.4),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 28059.7
        )
    }
}
