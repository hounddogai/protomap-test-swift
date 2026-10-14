import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual remittance proposal calculation.
    protocol ManualRemittanceProposalFactor {
        func describe() -> String
        func adjust(_ item: ManualRemittanceProposal, value: Double) -> Double
    }

    final class MinimumManualRemittanceProposalAdjuster: ManualRemittanceProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRemittanceProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualRemittanceProposalAdjuster: ManualRemittanceProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualRemittanceProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualRemittanceProposalAdjuster: ManualRemittanceProposalFactor {
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

        func adjust(_ item: ManualRemittanceProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual remittance proposal steps in order and keeps a trace of each.
    final class ManualRemittanceProposalEngine {
        var steps: [any ManualRemittanceProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRemittanceProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualRemittanceProposal) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualRemittanceProposalFactor = steps[index]
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

        func evaluateAll(_ items: [ManualRemittanceProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualRemittanceProposalEngine(_ flags: Kit.Flags.Registry) -> ManualRemittanceProposalEngine {
        return ManualRemittanceProposalEngine(
            steps: [
                MinimumManualRemittanceProposalAdjuster(minimum: 16.6),
                RoundingManualRemittanceProposalAdjuster(step: 5.0),
                FlaggedManualRemittanceProposalAdjuster(
                    flags: flags,
                    flag: "manual-remittance-proposal-seasonal",
                    percent: 1.3
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 15233.0
        )
    }
}
