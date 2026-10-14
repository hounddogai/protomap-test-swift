import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the manual overtime proposal calculation.
    protocol ManualOvertimeProposalModifier {
        func describe() -> String
        func adjust(_ item: ManualOvertimeProposal, value: Double) -> Double
    }

    final class CapManualOvertimeProposalAdjuster: ManualOvertimeProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualOvertimeProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentManualOvertimeProposalAdjuster: ManualOvertimeProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualOvertimeProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualOvertimeProposalAdjuster: ManualOvertimeProposalModifier {
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

        func adjust(_ item: ManualOvertimeProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the manual overtime proposal steps in order and keeps a trace of each.
    final class ManualOvertimeProposalEngine {
        var steps: [any ManualOvertimeProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOvertimeProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualOvertimeProposal) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ManualOvertimeProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualOvertimeProposalEngine(_ flags: Kit.Flags.Registry) -> ManualOvertimeProposalEngine {
        return ManualOvertimeProposalEngine(
            steps: [
                CapManualOvertimeProposalAdjuster(cap: 33127.0),
                PercentManualOvertimeProposalAdjuster(percent: 18.3),
                FlaggedManualOvertimeProposalAdjuster(
                    flags: flags,
                    flag: "manual-overtime-proposal-primary",
                    percent: 3.1
                ),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 62530.2
        )
    }
}
