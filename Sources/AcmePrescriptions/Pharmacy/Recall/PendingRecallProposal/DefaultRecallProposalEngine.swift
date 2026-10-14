import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default recall proposal calculation.
    protocol DefaultRecallProposalStep {
        func describe() -> String
        func adjust(_ item: DefaultRecallProposal, value: Double) -> Double
    }

    final class SegmentDefaultRecallProposalAdjuster: DefaultRecallProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DefaultRecallProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class DefaultRecallProposalMarginOffsetAdjuster: DefaultRecallProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: DefaultRecallProposal, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class PercentDefaultRecallProposalAdjuster: DefaultRecallProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultRecallProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultRecallProposalAdjuster: DefaultRecallProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRecallProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDefaultRecallProposalAdjuster: DefaultRecallProposalStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultRecallProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the default recall proposal steps in order and keeps a trace of each.
    final class DefaultRecallProposalEngine {
        var steps: [any DefaultRecallProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRecallProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultRecallProposal) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRecallProposalStep = steps[index]
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

        func evaluateAll(_ items: [DefaultRecallProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultRecallProposalEngine() -> DefaultRecallProposalEngine {
        return DefaultRecallProposalEngine(
            steps: [
                SegmentDefaultRecallProposalAdjuster(factors: ["online": 1.34]),
                DefaultRecallProposalMarginOffsetAdjuster(weight: 1.59),
                PercentDefaultRecallProposalAdjuster(percent: -16.5),
                MinimumDefaultRecallProposalAdjuster(minimum: 19.1),
                RoundingDefaultRecallProposalAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 48512.2
        )
    }
}
