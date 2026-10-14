import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal inventory rollup calculation.
    protocol SeasonalInventoryRollupStep {
        func describe() -> String
        func adjust(_ item: SeasonalInventoryRollup, value: Double) -> Double
    }

    final class CategorySeasonalInventoryRollupAdjuster: SeasonalInventoryRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: SeasonalInventoryRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalInventoryRollupRetriesOffsetAdjuster: SeasonalInventoryRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: SeasonalInventoryRollup, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class PercentSeasonalInventoryRollupAdjuster: SeasonalInventoryRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalInventoryRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSeasonalInventoryRollupAdjuster: SeasonalInventoryRollupStep {
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

        func adjust(_ item: SeasonalInventoryRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalInventoryRollupAdjuster: SeasonalInventoryRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalInventoryRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal inventory rollup steps in order and keeps a trace of each.
    final class SeasonalInventoryRollupEngine {
        var steps: [any SeasonalInventoryRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalInventoryRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalInventoryRollup) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalInventoryRollupStep = steps[index]
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

        func evaluateAll(_ items: [SeasonalInventoryRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalInventoryRollupEngine(_ flags: Kit.Flags.Registry) -> SeasonalInventoryRollupEngine {
        return SeasonalInventoryRollupEngine(
            steps: [
                CategorySeasonalInventoryRollupAdjuster(factors: ["east": 1.37, "north": 1.2]),
                SeasonalInventoryRollupRetriesOffsetAdjuster(weight: 0.76),
                PercentSeasonalInventoryRollupAdjuster(percent: 9.5),
                FlaggedSeasonalInventoryRollupAdjuster(
                    flags: flags,
                    flag: "seasonal-inventory-rollup-tiered",
                    percent: 2.2
                ),
                TieredSeasonalInventoryRollupAdjuster(bounds: [6408.0, 6837.0], rates: [1.03, 1.15]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 28357.2
        )
    }
}
