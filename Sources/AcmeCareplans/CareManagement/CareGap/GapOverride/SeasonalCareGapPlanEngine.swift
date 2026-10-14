import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the seasonal care gap plan calculation.
    protocol SeasonalCareGapPlanFactor {
        func describe() -> String
        func adjust(_ item: SeasonalCareGapPlan, value: Double) -> Double
    }

    final class PercentSeasonalCareGapPlanAdjuster: SeasonalCareGapPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalCareGapPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalCareGapPlanAdjuster: SeasonalCareGapPlanFactor {
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

        func adjust(_ item: SeasonalCareGapPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalCareGapPlanAdjuster: SeasonalCareGapPlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalCareGapPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the seasonal care gap plan steps in order and keeps a trace of each.
    final class SeasonalCareGapPlanEngine {
        var steps: [any SeasonalCareGapPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalCareGapPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalCareGapPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalCareGapPlanFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalCareGapPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalCareGapPlanEngine(_ flags: Kit.Flags.Registry) -> SeasonalCareGapPlanEngine {
        return SeasonalCareGapPlanEngine(
            steps: [
                PercentSeasonalCareGapPlanAdjuster(percent: 4.1),
                FlaggedSeasonalCareGapPlanAdjuster(
                    flags: flags,
                    flag: "seasonal-care-gap-plan-seasonal",
                    percent: 0.9
                ),
                MinimumSeasonalCareGapPlanAdjuster(minimum: 13.6),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 29342.8
        )
    }
}
