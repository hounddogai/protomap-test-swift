import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement proposal calculation.
    protocol StatementProposalAdjuster {
        func describe() -> String
        func adjust(_ item: StatementProposal, value: Double) -> Double
    }

    final class FlaggedStatementProposalAdjuster: StatementProposalAdjuster {
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

        func adjust(_ item: StatementProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStatementProposalAdjuster: StatementProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStatementProposalAdjuster: StatementProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStatementProposalAdjuster: StatementProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the statement proposal steps in order and keeps a trace of each.
    final class StatementProposalEngine {
        var steps: [any StatementProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementProposal) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StatementProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementProposalEngine(_ flags: Kit.Flags.Registry) -> StatementProposalEngine {
        return StatementProposalEngine(
            steps: [
                FlaggedStatementProposalAdjuster(flags: flags, flag: "statement-proposal-manual", percent: -3.3),
                RoundingStatementProposalAdjuster(step: 5.0),
                MinimumStatementProposalAdjuster(minimum: 16.9),
                CapStatementProposalAdjuster(cap: 4300.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 92757.6
        )
    }
}
