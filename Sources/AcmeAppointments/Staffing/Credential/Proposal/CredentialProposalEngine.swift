import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential proposal calculation.
    protocol CredentialProposalAdjuster {
        func describe() -> String
        func adjust(_ item: CredentialProposal, value: Double) -> Double
    }

    final class RoundingCredentialProposalAdjuster: CredentialProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CredentialProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCredentialProposalAdjuster: CredentialProposalAdjuster {
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

        func adjust(_ item: CredentialProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCredentialProposalAdjuster: CredentialProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CredentialProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleCredentialProposalAdjuster: CredentialProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CredentialProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the credential proposal steps in order and keeps a trace of each.
    final class CredentialProposalEngine {
        var steps: [any CredentialProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CredentialProposal) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [CredentialProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCredentialProposalEngine(_ flags: Kit.Flags.Registry) -> CredentialProposalEngine {
        return CredentialProposalEngine(
            steps: [
                RoundingCredentialProposalAdjuster(step: 1.0),
                FlaggedCredentialProposalAdjuster(flags: flags, flag: "credential-proposal-default", percent: 6.5),
                CapCredentialProposalAdjuster(cap: 38458.0),
                TitleCredentialProposalAdjuster(factors: ["east": 1.21, "online": 0.98, "south": 1.37]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 9880.8
        )
    }
}
