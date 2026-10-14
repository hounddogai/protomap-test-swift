import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal care gap tier calculation.
    protocol SeasonalCareGapTierStep {
        func describe() -> String
        func adjust(_ item: SeasonalCareGapTier, value: Double) -> Double
    }

    final class UnitSeasonalCareGapTierAdjuster: SeasonalCareGapTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: SeasonalCareGapTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalCareGapTierAdjuster: SeasonalCareGapTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCareGapTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSeasonalCareGapTierAdjuster: SeasonalCareGapTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalCareGapTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSeasonalCareGapTierAdjuster: SeasonalCareGapTierStep {
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

        func adjust(_ item: SeasonalCareGapTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal care gap tier steps in order and keeps a trace of each.
    final class SeasonalCareGapTierEngine {
        var steps: [any SeasonalCareGapTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareGapTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalCareGapTier) -> Double {
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

        func evaluateAll(_ items: [SeasonalCareGapTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareGapTierEngine(_ flags: Kit.Flags.Registry) -> SeasonalCareGapTierEngine {
        return SeasonalCareGapTierEngine(
            steps: [
                UnitSeasonalCareGapTierAdjuster(factors: ["east": 1.29]),
                MinimumSeasonalCareGapTierAdjuster(minimum: 14.9),
                RoundingSeasonalCareGapTierAdjuster(step: 5.0),
                FlaggedSeasonalCareGapTierAdjuster(flags: flags, flag: "seasonal-care-gap-tier-batched", percent: 7.6),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 70514.3
        )
    }
}
