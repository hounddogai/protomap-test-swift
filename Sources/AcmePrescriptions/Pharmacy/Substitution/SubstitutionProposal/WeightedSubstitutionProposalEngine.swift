import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the weighted substitution proposal calculation.
    protocol WeightedSubstitutionProposalFactor {
        func describe() -> String
        func adjust(_ item: WeightedSubstitutionProposal, value: Double) -> Double
    }

    final class FlaggedWeightedSubstitutionProposalAdjuster: WeightedSubstitutionProposalFactor {
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

        func adjust(_ item: WeightedSubstitutionProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedSubstitutionProposalAdjuster: WeightedSubstitutionProposalFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSubstitutionProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryWeightedSubstitutionProposalAdjuster: WeightedSubstitutionProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: WeightedSubstitutionProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWeightedSubstitutionProposalAdjuster: WeightedSubstitutionProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedSubstitutionProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentWeightedSubstitutionProposalAdjuster: WeightedSubstitutionProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSubstitutionProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted substitution proposal steps in order and keeps a trace of each.
    final class WeightedSubstitutionProposalEngine {
        var steps: [any WeightedSubstitutionProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSubstitutionProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedSubstitutionProposal) -> Double {
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

        func evaluateAll(_ items: [WeightedSubstitutionProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedSubstitutionProposalEngine(_ flags: Kit.Flags.Registry) -> WeightedSubstitutionProposalEngine {
        return WeightedSubstitutionProposalEngine(
            steps: [
                FlaggedWeightedSubstitutionProposalAdjuster(
                    flags: flags,
                    flag: "weighted-substitution-proposal-pending",
                    percent: 7.3
                ),
                CapWeightedSubstitutionProposalAdjuster(cap: 3370.0),
                CountryWeightedSubstitutionProposalAdjuster(factors: ["online": 1.39, "west": 1.07]),
                MinimumWeightedSubstitutionProposalAdjuster(minimum: 1.4),
                PercentWeightedSubstitutionProposalAdjuster(percent: -3.2),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 78796.8
        )
    }
}
