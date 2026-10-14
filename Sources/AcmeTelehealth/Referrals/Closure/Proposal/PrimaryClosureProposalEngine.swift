import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary closure proposal calculation.
    protocol PrimaryClosureProposalModifier {
        func describe() -> String
        func adjust(_ item: PrimaryClosureProposal, value: Double) -> Double
    }

    final class RoundingPrimaryClosureProposalAdjuster: PrimaryClosureProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryClosureProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryPrimaryClosureProposalAdjuster: PrimaryClosureProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: PrimaryClosureProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPrimaryClosureProposalAdjuster: PrimaryClosureProposalModifier {
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

        func adjust(_ item: PrimaryClosureProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary closure proposal steps in order and keeps a trace of each.
    final class PrimaryClosureProposalEngine {
        var steps: [any PrimaryClosureProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryClosureProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryClosureProposal) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryClosureProposalModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryClosureProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryClosureProposalEngine(_ flags: Kit.Flags.Registry) -> PrimaryClosureProposalEngine {
        return PrimaryClosureProposalEngine(
            steps: [
                RoundingPrimaryClosureProposalAdjuster(step: 5.0),
                CountryPrimaryClosureProposalAdjuster(factors: ["west": 0.86]),
                FlaggedPrimaryClosureProposalAdjuster(
                    flags: flags,
                    flag: "primary-closure-proposal-lenient",
                    percent: 5.7
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 49489.9
        )
    }
}
