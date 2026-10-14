import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure proposal calculation.
    protocol DisclosureProposalModifier {
        func describe() -> String
        func adjust(_ item: DisclosureProposal, value: Double) -> Double
    }

    final class RoundingDisclosureProposalAdjuster: DisclosureProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDisclosureProposalAdjuster: DisclosureProposalModifier {
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

        func adjust(_ item: DisclosureProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryDisclosureProposalAdjuster: DisclosureProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: DisclosureProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the disclosure proposal steps in order and keeps a trace of each.
    final class DisclosureProposalEngine {
        var steps: [any DisclosureProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosureProposal) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DisclosureProposalModifier = steps[index]
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

        func evaluateAll(_ items: [DisclosureProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosureProposalEngine(_ flags: Kit.Flags.Registry) -> DisclosureProposalEngine {
        return DisclosureProposalEngine(
            steps: [
                RoundingDisclosureProposalAdjuster(step: 0.5),
                FlaggedDisclosureProposalAdjuster(flags: flags, flag: "disclosure-proposal-rolling", percent: 2.9),
                CountryDisclosureProposalAdjuster(factors: ["central": 1.28, "west": 1.21]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 59534.8
        )
    }
}
