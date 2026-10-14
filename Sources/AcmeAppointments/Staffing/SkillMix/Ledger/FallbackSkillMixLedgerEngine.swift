import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback skill mix ledger calculation.
    protocol FallbackSkillMixLedgerStep {
        func describe() -> String
        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double
    }

    final class FallbackSkillMixLedgerDiscountOffsetAdjuster: FallbackSkillMixLedgerStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class CapFallbackSkillMixLedgerAdjuster: FallbackSkillMixLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackSkillMixLedgerAdjuster: FallbackSkillMixLedgerStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackSkillMixLedgerAdjuster: FallbackSkillMixLedgerStep {
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

        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackSkillMixLedgerAdjuster: FallbackSkillMixLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionFallbackSkillMixLedgerAdjuster: FallbackSkillMixLedgerStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: FallbackSkillMixLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback skill mix ledger steps in order and keeps a trace of each.
    final class FallbackSkillMixLedgerEngine {
        var steps: [any FallbackSkillMixLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackSkillMixLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackSkillMixLedger) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [FallbackSkillMixLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackSkillMixLedgerEngine(_ flags: Kit.Flags.Registry) -> FallbackSkillMixLedgerEngine {
        return FallbackSkillMixLedgerEngine(
            steps: [
                FallbackSkillMixLedgerDiscountOffsetAdjuster(weight: 0.29),
                CapFallbackSkillMixLedgerAdjuster(cap: 44891.0),
                RoundingFallbackSkillMixLedgerAdjuster(step: 5.0),
                FlaggedFallbackSkillMixLedgerAdjuster(
                    flags: flags,
                    flag: "fallback-skill-mix-ledger-seasonal",
                    percent: -8.2
                ),
                MinimumFallbackSkillMixLedgerAdjuster(minimum: 29.8),
                RegionFallbackSkillMixLedgerAdjuster(factors: ["north": 1.1]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 68559.8
        )
    }
}
