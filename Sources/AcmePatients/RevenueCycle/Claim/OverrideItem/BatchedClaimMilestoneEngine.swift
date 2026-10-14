import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched claim milestone calculation.
    protocol BatchedClaimMilestoneStep {
        func describe() -> String
        func adjust(_ item: BatchedClaimMilestone, value: Double) -> Double
    }

    final class PercentBatchedClaimMilestoneAdjuster: BatchedClaimMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedClaimMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedClaimMilestoneAdjuster: BatchedClaimMilestoneStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedClaimMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitBatchedClaimMilestoneAdjuster: BatchedClaimMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: BatchedClaimMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched claim milestone steps in order and keeps a trace of each.
    final class BatchedClaimMilestoneEngine {
        var steps: [any BatchedClaimMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedClaimMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedClaimMilestone) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [BatchedClaimMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedClaimMilestoneEngine() -> BatchedClaimMilestoneEngine {
        return BatchedClaimMilestoneEngine(
            steps: [
                PercentBatchedClaimMilestoneAdjuster(percent: -18.4),
                CapBatchedClaimMilestoneAdjuster(cap: 46294.0),
                UnitBatchedClaimMilestoneAdjuster(factors: ["retail": 1.29, "east": 1.22, "north": 1.36]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 72776.4
        )
    }
}
