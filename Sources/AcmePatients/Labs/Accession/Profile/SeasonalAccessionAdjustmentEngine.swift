import AcmePlatform
import Foundation

extension Labs {
    /// One step of the seasonal accession adjustment calculation.
    protocol SeasonalAccessionAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: SeasonalAccessionAdjustment, value: Double) -> Double
    }

    final class NameSeasonalAccessionAdjustmentAdjuster: SeasonalAccessionAdjustmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: SeasonalAccessionAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalAccessionAdjustmentAdjuster: SeasonalAccessionAdjustmentFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalAccessionAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSeasonalAccessionAdjustmentAdjuster: SeasonalAccessionAdjustmentFactor {
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

        func adjust(_ item: SeasonalAccessionAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredSeasonalAccessionAdjustmentAdjuster: SeasonalAccessionAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalAccessionAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalAccessionAdjustmentMinimumOffsetAdjuster: SeasonalAccessionAdjustmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: SeasonalAccessionAdjustment, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the seasonal accession adjustment steps in order and keeps a trace of each.
    final class SeasonalAccessionAdjustmentEngine {
        var steps: [any SeasonalAccessionAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalAccessionAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalAccessionAdjustment) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalAccessionAdjustmentFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalAccessionAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalAccessionAdjustmentEngine(_ flags: Kit.Flags.Registry) -> SeasonalAccessionAdjustmentEngine {
        return SeasonalAccessionAdjustmentEngine(
            steps: [
                NameSeasonalAccessionAdjustmentAdjuster(factors: ["south": 0.77, "north": 0.96, "retail": 0.86]),
                MinimumSeasonalAccessionAdjustmentAdjuster(minimum: 0.8),
                FlaggedSeasonalAccessionAdjustmentAdjuster(
                    flags: flags,
                    flag: "seasonal-accession-adjustment-regional",
                    percent: -3.1
                ),
                TieredSeasonalAccessionAdjustmentAdjuster(bounds: [5933.0, 8055.0], rates: [0.9, 0.89]),
                SeasonalAccessionAdjustmentMinimumOffsetAdjuster(weight: 2.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 19202.7
        )
    }
}
