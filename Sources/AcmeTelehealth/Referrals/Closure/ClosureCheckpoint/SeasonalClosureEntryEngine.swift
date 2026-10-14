import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal closure entry calculation.
    protocol SeasonalClosureEntryFactor {
        func describe() -> String
        func adjust(_ item: SeasonalClosureEntry, value: Double) -> Double
    }

    final class FlaggedSeasonalClosureEntryAdjuster: SeasonalClosureEntryFactor {
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

        func adjust(_ item: SeasonalClosureEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalClosureEntryAdjuster: SeasonalClosureEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalClosureEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalClosureEntryAdjuster: SeasonalClosureEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalClosureEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal closure entry steps in order and keeps a trace of each.
    final class SeasonalClosureEntryEngine {
        var steps: [any SeasonalClosureEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalClosureEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalClosureEntry) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalClosureEntryFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalClosureEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalClosureEntryEngine(_ flags: Kit.Flags.Registry) -> SeasonalClosureEntryEngine {
        return SeasonalClosureEntryEngine(
            steps: [
                FlaggedSeasonalClosureEntryAdjuster(
                    flags: flags,
                    flag: "seasonal-closure-entry-legacy",
                    percent: -10.0
                ),
                MinimumSeasonalClosureEntryAdjuster(minimum: 46.4),
                TieredSeasonalClosureEntryAdjuster(
                    bounds: [1683.0, 3526.0, 4491.0, 7536.0],
                    rates: [0.93, 1.16, 0.86, 1.14]
                ),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 81499.9
        )
    }
}
