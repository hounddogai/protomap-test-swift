import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the assessment proposal calculation.
    protocol AssessmentProposalFactor {
        func describe() -> String
        func adjust(_ item: AssessmentProposal, value: Double) -> Double
    }

    final class FlaggedAssessmentProposalAdjuster: AssessmentProposalFactor {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: AssessmentProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleAssessmentProposalAdjuster: AssessmentProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AssessmentProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAssessmentProposalAdjuster: AssessmentProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AssessmentProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAssessmentProposalAdjuster: AssessmentProposalFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AssessmentProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAssessmentProposalAdjuster: AssessmentProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AssessmentProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the assessment proposal steps in order and keeps a trace of each.
    final class AssessmentProposalEngine {
        var steps: [any AssessmentProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AssessmentProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AssessmentProposal) -> Double {
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

        func evaluateAll(_ items: [AssessmentProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAssessmentProposalEngine(_ flags: Kit.Flags.Registry) -> AssessmentProposalEngine {
        return AssessmentProposalEngine(
            steps: [
                FlaggedAssessmentProposalAdjuster(flags: flags, flag: "assessment-proposal-rolling", percent: -5.8),
                TitleAssessmentProposalAdjuster(factors: ["west": 1.37]),
                RoundingAssessmentProposalAdjuster(step: 0.25),
                TieredAssessmentProposalAdjuster(bounds: [223.0, 2164.0], rates: [0.89, 1.15]),
                MinimumAssessmentProposalAdjuster(minimum: 27.1),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 74632.7
        )
    }
}
