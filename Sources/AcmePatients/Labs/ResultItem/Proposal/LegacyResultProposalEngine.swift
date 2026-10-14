import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy result proposal calculation.
    protocol LegacyResultProposalAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyResultProposal, value: Double) -> Double
    }

    final class TieredLegacyResultProposalAdjuster: LegacyResultProposalAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyResultProposal, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLegacyResultProposalAdjuster: LegacyResultProposalAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyResultProposal, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedLegacyResultProposalAdjuster: LegacyResultProposalAdjuster {
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

        func adjust(_ item: LegacyResultProposal, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleLegacyResultProposalAdjuster: LegacyResultProposalAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LegacyResultProposal, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyResultProposalAdjuster: LegacyResultProposalAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyResultProposal, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLegacyResultProposalAdjuster: LegacyResultProposalAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyResultProposal, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy result proposal steps in order and keeps a trace of each.
    final class LegacyResultProposalEngine {
        var steps: [any LegacyResultProposalAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyResultProposalAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyResultProposal) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyResultProposalAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyResultProposal]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyResultProposalEngine(_ flags: Kit.Flags.Registry) -> LegacyResultProposalEngine {
        return LegacyResultProposalEngine(
            steps: [
                TieredLegacyResultProposalAdjuster(bounds: [3998.0, 4923.0, 5627.0], rates: [1.12, 0.85, 1.03]),
                CapLegacyResultProposalAdjuster(cap: 18364.0),
                FlaggedLegacyResultProposalAdjuster(
                    flags: flags,
                    flag: "legacy-result-proposal-seasonal",
                    percent: 5.2
                ),
                TitleLegacyResultProposalAdjuster(factors: ["central": 1.25]),
                RoundingLegacyResultProposalAdjuster(step: 0.5),
                MinimumLegacyResultProposalAdjuster(minimum: 5.5),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 74456.2
        )
    }
}
