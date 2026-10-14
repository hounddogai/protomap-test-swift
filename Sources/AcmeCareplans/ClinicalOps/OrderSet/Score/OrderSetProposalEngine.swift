import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set proposal calculation.
    protocol OrderSetProposalModifier {
        func describe() -> String
        func adjust(_ item: OrderSetProposal, value: Double) -> Double
    }

    final class FlaggedOrderSetProposalAdjuster: OrderSetProposalModifier {
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

        func adjust(_ item: OrderSetProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapOrderSetProposalAdjuster: OrderSetProposalModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingOrderSetProposalAdjuster: OrderSetProposalModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleOrderSetProposalAdjuster: OrderSetProposalModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OrderSetProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentOrderSetProposalAdjuster: OrderSetProposalModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: OrderSetProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the order set proposal steps in order and keeps a trace of each.
    final class OrderSetProposalEngine {
        var steps: [any OrderSetProposalModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetProposalModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetProposal) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [OrderSetProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetProposalEngine(_ flags: Kit.Flags.Registry) -> OrderSetProposalEngine {
        return OrderSetProposalEngine(
            steps: [
                FlaggedOrderSetProposalAdjuster(flags: flags, flag: "order-set-proposal-seasonal", percent: -1.4),
                CapOrderSetProposalAdjuster(cap: 4942.0),
                RoundingOrderSetProposalAdjuster(step: 0.05),
                LocaleOrderSetProposalAdjuster(factors: ["retail": 1.03, "west": 1.05, "east": 1.13]),
                PercentOrderSetProposalAdjuster(percent: -24.9),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 75154.4
        )
    }
}
