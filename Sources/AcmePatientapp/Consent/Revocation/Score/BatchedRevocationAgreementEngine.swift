import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched revocation agreement calculation.
    protocol BatchedRevocationAgreementFactor {
        func describe() -> String
        func adjust(_ item: BatchedRevocationAgreement, value: Double) -> Double
    }

    final class BatchedRevocationAgreementDiscountOffsetAdjuster: BatchedRevocationAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: BatchedRevocationAgreement, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingBatchedRevocationAgreementAdjuster: BatchedRevocationAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedRevocationAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedRevocationAgreementAdjuster: BatchedRevocationAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRevocationAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumBatchedRevocationAgreementAdjuster: BatchedRevocationAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedRevocationAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched revocation agreement steps in order and keeps a trace of each.
    final class BatchedRevocationAgreementEngine {
        var steps: [any BatchedRevocationAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRevocationAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedRevocationAgreement) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [BatchedRevocationAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedRevocationAgreementEngine() -> BatchedRevocationAgreementEngine {
        return BatchedRevocationAgreementEngine(
            steps: [
                BatchedRevocationAgreementDiscountOffsetAdjuster(weight: 1.51),
                RoundingBatchedRevocationAgreementAdjuster(step: 1.0),
                TieredBatchedRevocationAgreementAdjuster(bounds: [1103.0, 9772.0], rates: [0.85, 1.04]),
                MinimumBatchedRevocationAgreementAdjuster(minimum: 0.3),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 43511.1
        )
    }
}
