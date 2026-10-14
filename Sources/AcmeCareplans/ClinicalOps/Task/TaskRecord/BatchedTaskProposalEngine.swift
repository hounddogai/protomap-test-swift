import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched task proposal calculation.
    protocol BatchedTaskProposalFactor {
        func describe() -> String
        func adjust(_ item: BatchedTaskProposal, value: Double) -> Double
    }

    final class TieredBatchedTaskProposalAdjuster: BatchedTaskProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedTaskProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedTaskProposalAdjuster: BatchedTaskProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedTaskProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelBatchedTaskProposalAdjuster: BatchedTaskProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedTaskProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedTaskProposalAdjuster: BatchedTaskProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedTaskProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedTaskProposalAdjuster: BatchedTaskProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedTaskProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched task proposal steps in order and keeps a trace of each.
    final class BatchedTaskProposalEngine {
        var steps: [any BatchedTaskProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedTaskProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedTaskProposal) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [BatchedTaskProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedTaskProposalEngine() -> BatchedTaskProposalEngine {
        return BatchedTaskProposalEngine(
            steps: [
                TieredBatchedTaskProposalAdjuster(bounds: [2011.0, 5852.0], rates: [0.82, 1.16]),
                RoundingBatchedTaskProposalAdjuster(step: 0.5),
                LabelBatchedTaskProposalAdjuster(factors: ["west": 1.23, "central": 1.36, "north": 0.88]),
                MinimumBatchedTaskProposalAdjuster(minimum: 14.3),
                CapBatchedTaskProposalAdjuster(cap: 29787.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 67076.3
        )
    }
}
