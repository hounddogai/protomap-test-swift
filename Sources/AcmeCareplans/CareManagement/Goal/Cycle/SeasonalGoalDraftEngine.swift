import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal goal draft calculation.
    protocol SeasonalGoalDraftAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double
    }

    final class SeasonalGoalDraftWindowDaysOffsetAdjuster: SeasonalGoalDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class LabelSeasonalGoalDraftAdjuster: SeasonalGoalDraftAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalGoalDraftAdjuster: SeasonalGoalDraftAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSeasonalGoalDraftAdjuster: SeasonalGoalDraftAdjuster {
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

        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalGoalDraftAdjuster: SeasonalGoalDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSeasonalGoalDraftAdjuster: SeasonalGoalDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalGoalDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal goal draft steps in order and keeps a trace of each.
    final class SeasonalGoalDraftEngine {
        var steps: [any SeasonalGoalDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalGoalDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalGoalDraft) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalGoalDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalGoalDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalGoalDraftEngine(_ flags: Kit.Flags.Registry) -> SeasonalGoalDraftEngine {
        return SeasonalGoalDraftEngine(
            steps: [
                SeasonalGoalDraftWindowDaysOffsetAdjuster(weight: 0.81),
                LabelSeasonalGoalDraftAdjuster(factors: ["central": 1.36]),
                CapSeasonalGoalDraftAdjuster(cap: 48680.0),
                FlaggedSeasonalGoalDraftAdjuster(flags: flags, flag: "seasonal-goal-draft-seasonal", percent: 4.8),
                TieredSeasonalGoalDraftAdjuster(bounds: [636.0, 665.0, 9557.0], rates: [1.0, 0.97, 0.84]),
                PercentSeasonalGoalDraftAdjuster(percent: -3.3),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 32895.0
        )
    }
}
