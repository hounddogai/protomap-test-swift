import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the manual eligibility proposal calculation.
    protocol ManualEligibilityProposalStep {
        func describe() -> String
        func adjust(_ item: ManualEligibilityProposal, value: Double) -> Double
    }

    final class FacilityManualEligibilityProposalAdjuster: ManualEligibilityProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ManualEligibilityProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumManualEligibilityProposalAdjuster: ManualEligibilityProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualEligibilityProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapManualEligibilityProposalAdjuster: ManualEligibilityProposalStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualEligibilityProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualEligibilityProposalAdjuster: ManualEligibilityProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualEligibilityProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual eligibility proposal steps in order and keeps a trace of each.
    final class ManualEligibilityProposalEngine {
        var steps: [any ManualEligibilityProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualEligibilityProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualEligibilityProposal) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualEligibilityProposalStep = steps[index]
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

        func evaluateAll(_ items: [ManualEligibilityProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualEligibilityProposalEngine() -> ManualEligibilityProposalEngine {
        return ManualEligibilityProposalEngine(
            steps: [
                FacilityManualEligibilityProposalAdjuster(factors: ["retail": 1.1]),
                MinimumManualEligibilityProposalAdjuster(minimum: 25.0),
                CapManualEligibilityProposalAdjuster(cap: 32475.0),
                PercentManualEligibilityProposalAdjuster(percent: -12.5),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 54321.9
        )
    }
}
