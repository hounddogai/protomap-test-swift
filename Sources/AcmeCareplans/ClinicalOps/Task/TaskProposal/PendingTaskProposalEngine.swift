import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the pending task proposal calculation.
    protocol PendingTaskProposalStep {
        func describe() -> String
        func adjust(_ item: PendingTaskProposal, value: Double) -> Double
    }

    final class LabelPendingTaskProposalAdjuster: PendingTaskProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingTaskProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingTaskProposalAdjuster: PendingTaskProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingTaskProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentPendingTaskProposalAdjuster: PendingTaskProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingTaskProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingTaskProposalAdjuster: PendingTaskProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingTaskProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredPendingTaskProposalAdjuster: PendingTaskProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingTaskProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending task proposal steps in order and keeps a trace of each.
    final class PendingTaskProposalEngine {
        var steps: [any PendingTaskProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingTaskProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingTaskProposal) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingTaskProposalStep = steps[index]
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

        func evaluateAll(_ items: [PendingTaskProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingTaskProposalEngine() -> PendingTaskProposalEngine {
        return PendingTaskProposalEngine(
            steps: [
                LabelPendingTaskProposalAdjuster(factors: ["west": 0.85, "north": 1.36]),
                MinimumPendingTaskProposalAdjuster(minimum: 28.9),
                PercentPendingTaskProposalAdjuster(percent: 3.8),
                CapPendingTaskProposalAdjuster(cap: 35491.0),
                TieredPendingTaskProposalAdjuster(bounds: [601.0, 4624.0], rates: [0.86, 1.15]),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 93915.1
        )
    }
}
