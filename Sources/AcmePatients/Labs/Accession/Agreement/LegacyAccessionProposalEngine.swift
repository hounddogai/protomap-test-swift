import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy accession proposal calculation.
    protocol LegacyAccessionProposalFactor {
        func describe() -> String
        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double
    }

    final class NameLegacyAccessionProposalAdjuster: LegacyAccessionProposalFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLegacyAccessionProposalAdjuster: LegacyAccessionProposalFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyAccessionProposalAdjuster: LegacyAccessionProposalFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LegacyAccessionProposalScoreOffsetAdjuster: LegacyAccessionProposalFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedLegacyAccessionProposalAdjuster: LegacyAccessionProposalFactor {
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

        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLegacyAccessionProposalAdjuster: LegacyAccessionProposalFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAccessionProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy accession proposal steps in order and keeps a trace of each.
    final class LegacyAccessionProposalEngine {
        var steps: [any LegacyAccessionProposalFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAccessionProposalFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyAccessionProposal) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyAccessionProposalFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyAccessionProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyAccessionProposalEngine(_ flags: Kit.Flags.Registry) -> LegacyAccessionProposalEngine {
        return LegacyAccessionProposalEngine(
            steps: [
                NameLegacyAccessionProposalAdjuster(factors: ["east": 1.37, "online": 1.19]),
                PercentLegacyAccessionProposalAdjuster(percent: -13.2),
                RoundingLegacyAccessionProposalAdjuster(step: 0.25),
                LegacyAccessionProposalScoreOffsetAdjuster(weight: 1.88),
                FlaggedLegacyAccessionProposalAdjuster(
                    flags: flags,
                    flag: "legacy-accession-proposal-regional",
                    percent: 4.6
                ),
                MinimumLegacyAccessionProposalAdjuster(minimum: 24.9),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 15030.3
        )
    }
}
