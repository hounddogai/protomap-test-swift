import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default cleaning proposal calculation.
    protocol DefaultCleaningProposalStep {
        func describe() -> String
        func adjust(_ item: DefaultCleaningProposal, value: Double) -> Double
    }

    final class SegmentDefaultCleaningProposalAdjuster: DefaultCleaningProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DefaultCleaningProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultCleaningProposalAdjuster: DefaultCleaningProposalStep {
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

        func adjust(_ item: DefaultCleaningProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultCleaningProposalAdjuster: DefaultCleaningProposalStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCleaningProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default cleaning proposal steps in order and keeps a trace of each.
    final class DefaultCleaningProposalEngine {
        var steps: [any DefaultCleaningProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCleaningProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultCleaningProposal) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCleaningProposalStep = steps[index]
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

        func evaluateAll(_ items: [DefaultCleaningProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultCleaningProposalEngine(_ flags: Kit.Flags.Registry) -> DefaultCleaningProposalEngine {
        return DefaultCleaningProposalEngine(
            steps: [
                SegmentDefaultCleaningProposalAdjuster(factors: ["west": 1.1, "north": 0.95, "central": 1.2]),
                FlaggedDefaultCleaningProposalAdjuster(
                    flags: flags,
                    flag: "default-cleaning-proposal-primary",
                    percent: -3.1
                ),
                PercentDefaultCleaningProposalAdjuster(percent: -18.2),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 8162.8
        )
    }
}
