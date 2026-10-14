import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the weighted read proposal calculation.
    protocol WeightedReadProposalAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedReadProposal, value: Double) -> Double
    }

    final class PercentWeightedReadProposalAdjuster: WeightedReadProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedReadProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedReadProposalAdjuster: WeightedReadProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedReadProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WeightedReadProposalRateOffsetAdjuster: WeightedReadProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: WeightedReadProposal, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapWeightedReadProposalAdjuster: WeightedReadProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedReadProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted read proposal steps in order and keeps a trace of each.
    final class WeightedReadProposalEngine {
        var steps: [any WeightedReadProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedReadProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: WeightedReadProposal) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedReadProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedReadProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultWeightedReadProposalEngine() -> WeightedReadProposalEngine {
        return WeightedReadProposalEngine(
            steps: [
                PercentWeightedReadProposalAdjuster(percent: 13.6),
                MinimumWeightedReadProposalAdjuster(minimum: 18.8),
                WeightedReadProposalRateOffsetAdjuster(weight: 0.23),
                CapWeightedReadProposalAdjuster(cap: 27667.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 60311.5
        )
    }
}
