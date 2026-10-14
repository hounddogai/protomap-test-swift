import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal reference range schedule calculation.
    protocol SeasonalReferenceRangeScheduleFactor {
        func describe() -> String
        func adjust(_ item: SeasonalReferenceRangeSchedule, value: Double) -> Double
    }

    final class TieredSeasonalReferenceRangeScheduleAdjuster: SeasonalReferenceRangeScheduleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalReferenceRangeSchedule, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedSeasonalReferenceRangeScheduleAdjuster: SeasonalReferenceRangeScheduleFactor {
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

        func adjust(_ item: SeasonalReferenceRangeSchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalReferenceRangeScheduleAdjuster: SeasonalReferenceRangeScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalReferenceRangeSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SeasonalReferenceRangeScheduleRateOffsetAdjuster: SeasonalReferenceRangeScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: SeasonalReferenceRangeSchedule, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapSeasonalReferenceRangeScheduleAdjuster: SeasonalReferenceRangeScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalReferenceRangeSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal reference range schedule steps in order and keeps a trace of each.
    final class SeasonalReferenceRangeScheduleEngine {
        var steps: [any SeasonalReferenceRangeScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReferenceRangeScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalReferenceRangeSchedule) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalReferenceRangeScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalReferenceRangeSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalReferenceRangeScheduleEngine(_ flags: Kit.Flags.Registry) -> SeasonalReferenceRangeScheduleEngine {
        return SeasonalReferenceRangeScheduleEngine(
            steps: [
                TieredSeasonalReferenceRangeScheduleAdjuster(bounds: [374.0, 5461.0], rates: [0.99, 0.86]),
                FlaggedSeasonalReferenceRangeScheduleAdjuster(
                    flags: flags,
                    flag: "seasonal-reference-range-schedule-adaptive",
                    percent: -1.2
                ),
                MinimumSeasonalReferenceRangeScheduleAdjuster(minimum: 20.2),
                SeasonalReferenceRangeScheduleRateOffsetAdjuster(weight: 1.75),
                CapSeasonalReferenceRangeScheduleAdjuster(cap: 37529.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 51056.2
        )
    }
}
