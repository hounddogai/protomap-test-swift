import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal substitution quota calculation.
    protocol SeasonalSubstitutionQuotaModifier {
        func describe() -> String
        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double
    }

    final class TitleSeasonalSubstitutionQuotaAdjuster: SeasonalSubstitutionQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedSeasonalSubstitutionQuotaAdjuster: SeasonalSubstitutionQuotaModifier {
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

        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalSubstitutionQuotaAdjuster: SeasonalSubstitutionQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalSubstitutionQuotaScoreOffsetAdjuster: SeasonalSubstitutionQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentSeasonalSubstitutionQuotaAdjuster: SeasonalSubstitutionQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalSubstitutionQuotaAdjuster: SeasonalSubstitutionQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalSubstitutionQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal substitution quota steps in order and keeps a trace of each.
    final class SeasonalSubstitutionQuotaEngine {
        var steps: [any SeasonalSubstitutionQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSubstitutionQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalSubstitutionQuota) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalSubstitutionQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalSubstitutionQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalSubstitutionQuotaEngine(_ flags: Kit.Flags.Registry) -> SeasonalSubstitutionQuotaEngine {
        return SeasonalSubstitutionQuotaEngine(
            steps: [
                TitleSeasonalSubstitutionQuotaAdjuster(factors: ["central": 1.13]),
                FlaggedSeasonalSubstitutionQuotaAdjuster(
                    flags: flags,
                    flag: "seasonal-substitution-quota-default",
                    percent: 3.4
                ),
                CapSeasonalSubstitutionQuotaAdjuster(cap: 33848.0),
                SeasonalSubstitutionQuotaScoreOffsetAdjuster(weight: 0.87),
                PercentSeasonalSubstitutionQuotaAdjuster(percent: 12.8),
                RoundingSeasonalSubstitutionQuotaAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 88922.9
        )
    }
}
