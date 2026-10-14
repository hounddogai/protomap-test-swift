import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the tiered skill mix digest calculation.
    protocol ProposalTieredSkillMixDigestAdjuster {
        func describe() -> String
        func adjust(_ item: TieredSkillMixDigest, value: Double) -> Double
    }

    final class RoundingTieredSkillMixDigestAdjuster: ProposalTieredSkillMixDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredSkillMixDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedTieredSkillMixDigestAdjuster: ProposalTieredSkillMixDigestAdjuster {
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

        func adjust(_ item: TieredSkillMixDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentTieredSkillMixDigestAdjuster: ProposalTieredSkillMixDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredSkillMixDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryTieredSkillMixDigestAdjuster: ProposalTieredSkillMixDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: TieredSkillMixDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumTieredSkillMixDigestAdjuster: ProposalTieredSkillMixDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredSkillMixDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered skill mix digest steps in order and keeps a trace of each.
    final class TieredSkillMixDigestEngine {
        var steps: [any ProposalTieredSkillMixDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProposalTieredSkillMixDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredSkillMixDigest) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [TieredSkillMixDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredSkillMixDigestEngine(_ flags: Kit.Flags.Registry) -> TieredSkillMixDigestEngine {
        return TieredSkillMixDigestEngine(
            steps: [
                RoundingTieredSkillMixDigestAdjuster(step: 1.0),
                FlaggedTieredSkillMixDigestAdjuster(
                    flags: flags,
                    flag: "tiered-skill-mix-digest-batched",
                    percent: 9.5
                ),
                PercentTieredSkillMixDigestAdjuster(percent: 11.8),
                CategoryTieredSkillMixDigestAdjuster(factors: ["retail": 1.34, "south": 0.75]),
                MinimumTieredSkillMixDigestAdjuster(minimum: 21.3),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 32358.1
        )
    }
}
