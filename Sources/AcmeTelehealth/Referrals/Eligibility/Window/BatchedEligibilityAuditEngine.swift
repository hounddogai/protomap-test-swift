import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched eligibility audit calculation.
    protocol BatchedEligibilityAuditFactor {
        func describe() -> String
        func adjust(_ item: BatchedEligibilityAudit, value: Double) -> Double
    }

    final class TieredBatchedEligibilityAuditAdjuster: BatchedEligibilityAuditFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedEligibilityAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedEligibilityAuditAdjuster: BatchedEligibilityAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedEligibilityAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentBatchedEligibilityAuditAdjuster: BatchedEligibilityAuditFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedEligibilityAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedEligibilityAuditAdjuster: BatchedEligibilityAuditFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedEligibilityAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched eligibility audit steps in order and keeps a trace of each.
    final class BatchedEligibilityAuditEngine {
        var steps: [any BatchedEligibilityAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedEligibilityAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedEligibilityAudit) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [BatchedEligibilityAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedEligibilityAuditEngine() -> BatchedEligibilityAuditEngine {
        return BatchedEligibilityAuditEngine(
            steps: [
                TieredBatchedEligibilityAuditAdjuster(
                    bounds: [2326.0, 4223.0, 5593.0, 7964.0],
                    rates: [1.19, 1.0, 1.01, 1.06]
                ),
                RoundingBatchedEligibilityAuditAdjuster(step: 0.1),
                PercentBatchedEligibilityAuditAdjuster(percent: 14.7),
                MinimumBatchedEligibilityAuditAdjuster(minimum: 10.3),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 17970.5
        )
    }
}
