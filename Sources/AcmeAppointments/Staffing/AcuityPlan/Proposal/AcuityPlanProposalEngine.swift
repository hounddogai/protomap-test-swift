import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan proposal calculation.
    protocol AcuityPlanProposalStep {
        func describe() -> String
        func adjust(_ item: AcuityPlanProposal, value: Double) -> Double
    }

    final class AcuityPlanProposalStartsAtOffsetAdjuster: AcuityPlanProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: AcuityPlanProposal, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentAcuityPlanProposalAdjuster: AcuityPlanProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAcuityPlanProposalAdjuster: AcuityPlanProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AcuityPlanProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the acuity plan proposal steps in order and keeps a trace of each.
    final class AcuityPlanProposalEngine {
        var steps: [any AcuityPlanProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AcuityPlanProposal) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanProposalStep = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanProposalEngine() -> AcuityPlanProposalEngine {
        return AcuityPlanProposalEngine(
            steps: [
                AcuityPlanProposalStartsAtOffsetAdjuster(weight: 1.25),
                PercentAcuityPlanProposalAdjuster(percent: -14.1),
                TitleAcuityPlanProposalAdjuster(factors: ["central": 1.1]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 18362.4
        )
    }
}
