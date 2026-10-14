import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result proposal calculation.
    protocol ResultProposalModifier {
        func describe() -> String
        func adjust(_ item: ResultProposal, value: Double) -> Double
    }

    final class ChannelResultProposalAdjuster: ResultProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ResultProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapResultProposalAdjuster: ResultProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ResultProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentResultProposalAdjuster: ResultProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedResultProposalAdjuster: ResultProposalModifier {
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

        func adjust(_ item: ResultProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the result proposal steps in order and keeps a trace of each.
    final class ResultProposalEngine {
        var steps: [any ResultProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ResultProposal) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ResultProposalModifier = steps[index]
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

        func evaluateAll(_ items: [ResultProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultResultProposalEngine(_ flags: Kit.Flags.Registry) -> ResultProposalEngine {
        return ResultProposalEngine(
            steps: [
                ChannelResultProposalAdjuster(factors: ["south": 1.25, "west": 0.94, "north": 1.34]),
                CapResultProposalAdjuster(cap: 42421.0),
                PercentResultProposalAdjuster(percent: 4.7),
                FlaggedResultProposalAdjuster(flags: flags, flag: "result-proposal-rolling", percent: 5.5),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 48564.2
        )
    }
}
