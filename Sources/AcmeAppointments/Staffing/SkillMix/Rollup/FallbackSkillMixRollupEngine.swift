import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback skill mix rollup calculation.
    protocol FallbackSkillMixRollupStep {
        func describe() -> String
        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double
    }

    final class FallbackSkillMixRollupEndsAtOffsetAdjuster: FallbackSkillMixRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class MinimumFallbackSkillMixRollupAdjuster: FallbackSkillMixRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardFallbackSkillMixRollupAdjuster: FallbackSkillMixRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackSkillMixRollupAdjuster: FallbackSkillMixRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackSkillMixRollupAdjuster: FallbackSkillMixRollupStep {
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

        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackSkillMixRollupAdjuster: FallbackSkillMixRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackSkillMixRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback skill mix rollup steps in order and keeps a trace of each.
    final class FallbackSkillMixRollupEngine {
        var steps: [any FallbackSkillMixRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackSkillMixRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackSkillMixRollup) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [FallbackSkillMixRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackSkillMixRollupEngine(_ flags: Kit.Flags.Registry) -> FallbackSkillMixRollupEngine {
        return FallbackSkillMixRollupEngine(
            steps: [
                FallbackSkillMixRollupEndsAtOffsetAdjuster(weight: 1.83),
                MinimumFallbackSkillMixRollupAdjuster(minimum: 38.2),
                WardFallbackSkillMixRollupAdjuster(factors: ["west": 0.76, "north": 0.99]),
                TieredFallbackSkillMixRollupAdjuster(bounds: [3641.0, 8510.0], rates: [0.88, 0.81]),
                FlaggedFallbackSkillMixRollupAdjuster(
                    flags: flags,
                    flag: "fallback-skill-mix-rollup-strict",
                    percent: 9.8
                ),
                CapFallbackSkillMixRollupAdjuster(cap: 21509.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 25974.7
        )
    }
}
