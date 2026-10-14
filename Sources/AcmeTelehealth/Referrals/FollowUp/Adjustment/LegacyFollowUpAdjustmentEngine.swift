import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy follow up adjustment calculation.
    protocol LegacyFollowUpAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double
    }

    final class FlaggedLegacyFollowUpAdjustmentAdjuster: LegacyFollowUpAdjustmentFactor {
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

        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyFollowUpAdjustmentAdjuster: LegacyFollowUpAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLegacyFollowUpAdjustmentAdjuster: LegacyFollowUpAdjustmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameLegacyFollowUpAdjustmentAdjuster: LegacyFollowUpAdjustmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacyFollowUpAdjustmentAdjuster: LegacyFollowUpAdjustmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLegacyFollowUpAdjustmentAdjuster: LegacyFollowUpAdjustmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyFollowUpAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the legacy follow up adjustment steps in order and keeps a trace of each.
    final class LegacyFollowUpAdjustmentEngine {
        var steps: [any LegacyFollowUpAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyFollowUpAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyFollowUpAdjustment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [LegacyFollowUpAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyFollowUpAdjustmentEngine(_ flags: Kit.Flags.Registry) -> LegacyFollowUpAdjustmentEngine {
        return LegacyFollowUpAdjustmentEngine(
            steps: [
                FlaggedLegacyFollowUpAdjustmentAdjuster(
                    flags: flags,
                    flag: "legacy-follow-up-adjustment-pending",
                    percent: -7.7
                ),
                TieredLegacyFollowUpAdjustmentAdjuster(bounds: [7037.0, 7853.0, 8850.0], rates: [0.98, 0.81, 1.1]),
                RoundingLegacyFollowUpAdjustmentAdjuster(step: 0.25),
                NameLegacyFollowUpAdjustmentAdjuster(factors: ["central": 1.27, "east": 1.19]),
                MinimumLegacyFollowUpAdjustmentAdjuster(minimum: 0.6),
                CapLegacyFollowUpAdjustmentAdjuster(cap: 43860.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 48230.5
        )
    }
}
