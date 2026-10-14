import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up proposal calculation.
    protocol FollowUpProposalStep {
        func describe() -> String
        func adjust(_ item: FollowUpProposal, value: Double) -> Double
    }

    final class FlaggedFollowUpProposalAdjuster: FollowUpProposalStep {
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

        func adjust(_ item: FollowUpProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FollowUpProposalEndsAtOffsetAdjuster: FollowUpProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FollowUpProposal, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumFollowUpProposalAdjuster: FollowUpProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the follow up proposal steps in order and keeps a trace of each.
    final class FollowUpProposalEngine {
        var steps: [any FollowUpProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpProposal) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpProposalStep = steps[index]
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

        func evaluateAll(_ items: [FollowUpProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpProposalEngine(_ flags: Kit.Flags.Registry) -> FollowUpProposalEngine {
        return FollowUpProposalEngine(
            steps: [
                FlaggedFollowUpProposalAdjuster(flags: flags, flag: "follow-up-proposal-scheduled", percent: 0.1),
                FollowUpProposalEndsAtOffsetAdjuster(weight: 1.42),
                MinimumFollowUpProposalAdjuster(minimum: 10.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 58117.1
        )
    }
}
