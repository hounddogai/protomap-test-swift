import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default courier proposal calculation.
    protocol DefaultCourierProposalModifier {
        func describe() -> String
        func adjust(_ item: DefaultCourierProposal, value: Double) -> Double
    }

    final class SourceDefaultCourierProposalAdjuster: DefaultCourierProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DefaultCourierProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultCourierProposalAdjuster: DefaultCourierProposalModifier {
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

        func adjust(_ item: DefaultCourierProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultCourierProposalAdjuster: DefaultCourierProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultCourierProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultCourierProposalAdjuster: DefaultCourierProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultCourierProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default courier proposal steps in order and keeps a trace of each.
    final class DefaultCourierProposalEngine {
        var steps: [any DefaultCourierProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCourierProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultCourierProposal) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCourierProposalModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultCourierProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultCourierProposalEngine(_ flags: Kit.Flags.Registry) -> DefaultCourierProposalEngine {
        return DefaultCourierProposalEngine(
            steps: [
                SourceDefaultCourierProposalAdjuster(factors: ["west": 1.12, "north": 1.23, "online": 0.84]),
                FlaggedDefaultCourierProposalAdjuster(
                    flags: flags,
                    flag: "default-courier-proposal-weighted",
                    percent: 5.7
                ),
                CapDefaultCourierProposalAdjuster(cap: 39972.0),
                PercentDefaultCourierProposalAdjuster(percent: 21.4),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 55236.2
        )
    }
}
