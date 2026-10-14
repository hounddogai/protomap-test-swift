import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the legacy care protocol proposal calculation.
    protocol LegacyCareProtocolProposalStep {
        func describe() -> String
        func adjust(_ item: LegacyCareProtocolProposal, value: Double) -> Double
    }

    final class MinimumLegacyCareProtocolProposalAdjuster: LegacyCareProtocolProposalStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyCareProtocolProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyCareProtocolProposalAdjuster: LegacyCareProtocolProposalStep {
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

        func adjust(_ item: LegacyCareProtocolProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameLegacyCareProtocolProposalAdjuster: LegacyCareProtocolProposalStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyCareProtocolProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class LegacyCareProtocolProposalStartsAtOffsetAdjuster: LegacyCareProtocolProposalStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: LegacyCareProtocolProposal, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class TieredLegacyCareProtocolProposalAdjuster: LegacyCareProtocolProposalStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyCareProtocolProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy care protocol proposal steps in order and keeps a trace of each.
    final class LegacyCareProtocolProposalEngine {
        var steps: [any LegacyCareProtocolProposalStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyCareProtocolProposalStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyCareProtocolProposal) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyCareProtocolProposalStep = steps[index]
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

        func evaluateAll(_ items: [LegacyCareProtocolProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyCareProtocolProposalEngine(_ flags: Kit.Flags.Registry) -> LegacyCareProtocolProposalEngine {
        return LegacyCareProtocolProposalEngine(
            steps: [
                MinimumLegacyCareProtocolProposalAdjuster(minimum: 47.5),
                FlaggedLegacyCareProtocolProposalAdjuster(
                    flags: flags,
                    flag: "legacy-care-protocol-proposal-manual",
                    percent: 6.9
                ),
                NameLegacyCareProtocolProposalAdjuster(factors: ["retail": 0.83, "south": 1.23, "east": 0.9]),
                LegacyCareProtocolProposalStartsAtOffsetAdjuster(weight: 0.81),
                TieredLegacyCareProtocolProposalAdjuster(
                    bounds: [3064.0, 5602.0, 6048.0, 7143.0],
                    rates: [1.04, 1.15, 1.1, 0.88]
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 96680.6
        )
    }
}
