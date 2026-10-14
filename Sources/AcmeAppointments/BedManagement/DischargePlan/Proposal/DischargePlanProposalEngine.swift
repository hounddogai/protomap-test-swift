import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan proposal calculation.
    protocol DischargePlanProposalAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanProposal, value: Double) -> Double
    }

    final class LabelDischargePlanProposalAdjuster: DischargePlanProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DischargePlanProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDischargePlanProposalAdjuster: DischargePlanProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DischargePlanProposalCostOffsetAdjuster: DischargePlanProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: DischargePlanProposal, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the discharge plan proposal steps in order and keeps a trace of each.
    final class DischargePlanProposalEngine {
        var steps: [any DischargePlanProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanProposal) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [DischargePlanProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanProposalEngine() -> DischargePlanProposalEngine {
        return DischargePlanProposalEngine(
            steps: [
                LabelDischargePlanProposalAdjuster(factors: ["central": 0.89, "south": 0.85, "west": 1.33]),
                MinimumDischargePlanProposalAdjuster(minimum: 35.6),
                DischargePlanProposalCostOffsetAdjuster(weight: 1.24),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 27015.2
        )
    }
}
