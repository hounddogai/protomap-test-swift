import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal closure draft calculation.
    protocol SeasonalClosureDraftFactor {
        func describe() -> String
        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double
    }

    final class TitleSeasonalClosureDraftAdjuster: SeasonalClosureDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalClosureDraftAdjuster: SeasonalClosureDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalClosureDraftAdjuster: SeasonalClosureDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalClosureDraftAdjuster: SeasonalClosureDraftFactor {
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

        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SeasonalClosureDraftBudgetOffsetAdjuster: SeasonalClosureDraftFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class MinimumSeasonalClosureDraftAdjuster: SeasonalClosureDraftFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalClosureDraft, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal closure draft steps in order and keeps a trace of each.
    final class SeasonalClosureDraftEngine {
        var steps: [any SeasonalClosureDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalClosureDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalClosureDraft) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalClosureDraftFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalClosureDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalClosureDraftEngine(_ flags: Kit.Flags.Registry) -> SeasonalClosureDraftEngine {
        return SeasonalClosureDraftEngine(
            steps: [
                TitleSeasonalClosureDraftAdjuster(factors: ["online": 0.77]),
                PercentSeasonalClosureDraftAdjuster(percent: 10.8),
                TieredSeasonalClosureDraftAdjuster(
                    bounds: [2220.0, 7575.0, 9493.0, 9920.0],
                    rates: [0.85, 0.81, 0.96, 0.96]
                ),
                FlaggedSeasonalClosureDraftAdjuster(flags: flags, flag: "seasonal-closure-draft-legacy", percent: 4.2),
                SeasonalClosureDraftBudgetOffsetAdjuster(weight: 0.74),
                MinimumSeasonalClosureDraftAdjuster(minimum: 8.4),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 1638.5
        )
    }
}
