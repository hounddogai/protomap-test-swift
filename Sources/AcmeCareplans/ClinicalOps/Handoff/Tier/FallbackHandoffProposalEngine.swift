import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the fallback handoff proposal calculation.
    protocol FallbackHandoffProposalAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackHandoffProposal, value: Double) -> Double
    }

    final class NameFallbackHandoffProposalAdjuster: FallbackHandoffProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: FallbackHandoffProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFallbackHandoffProposalAdjuster: FallbackHandoffProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackHandoffProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackHandoffProposalMinimumOffsetAdjuster: FallbackHandoffProposalAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: FallbackHandoffProposal, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedFallbackHandoffProposalAdjuster: FallbackHandoffProposalAdjuster {
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

        func adjust(_ item: FallbackHandoffProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback handoff proposal steps in order and keeps a trace of each.
    final class FallbackHandoffProposalEngine {
        var steps: [any FallbackHandoffProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackHandoffProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackHandoffProposal) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackHandoffProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackHandoffProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackHandoffProposalEngine(_ flags: Kit.Flags.Registry) -> FallbackHandoffProposalEngine {
        return FallbackHandoffProposalEngine(
            steps: [
                NameFallbackHandoffProposalAdjuster(factors: ["retail": 0.86, "online": 0.97, "north": 1.22]),
                RoundingFallbackHandoffProposalAdjuster(step: 0.5),
                FallbackHandoffProposalMinimumOffsetAdjuster(weight: 0.17),
                FlaggedFallbackHandoffProposalAdjuster(
                    flags: flags,
                    flag: "fallback-handoff-proposal-lenient",
                    percent: 1.0
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 33592.3
        )
    }
}
