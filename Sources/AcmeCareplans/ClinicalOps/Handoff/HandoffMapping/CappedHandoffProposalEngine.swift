import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the capped handoff proposal calculation.
    protocol CappedHandoffProposalAdjuster {
        func describe() -> String
        func adjust(_ item: CappedHandoffProposal, value: Double) -> Double
    }

    final class CapCappedHandoffProposalAdjuster: CappedHandoffProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedHandoffProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentCappedHandoffProposalAdjuster: CappedHandoffProposalAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedHandoffProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleCappedHandoffProposalAdjuster: CappedHandoffProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: CappedHandoffProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedHandoffProposalAdjuster: CappedHandoffProposalAdjuster {
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

        func adjust(_ item: CappedHandoffProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped handoff proposal steps in order and keeps a trace of each.
    final class CappedHandoffProposalEngine {
        var steps: [any CappedHandoffProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedHandoffProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedHandoffProposal) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [CappedHandoffProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedHandoffProposalEngine(_ flags: Kit.Flags.Registry) -> CappedHandoffProposalEngine {
        return CappedHandoffProposalEngine(
            steps: [
                CapCappedHandoffProposalAdjuster(cap: 49999.0),
                PercentCappedHandoffProposalAdjuster(percent: -7.5),
                TitleCappedHandoffProposalAdjuster(factors: ["east": 1.06, "west": 1.1, "central": 1.32]),
                FlaggedCappedHandoffProposalAdjuster(
                    flags: flags,
                    flag: "capped-handoff-proposal-rolling",
                    percent: -1.6
                ),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 2181.4
        )
    }
}
