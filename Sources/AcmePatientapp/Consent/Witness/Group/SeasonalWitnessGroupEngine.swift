import AcmePlatform
import Foundation

extension Consent {
    /// One step of the seasonal witness group calculation.
    protocol SeasonalWitnessGroupModifier {
        func describe() -> String
        func adjust(_ item: SeasonalWitnessGroup, value: Double) -> Double
    }

    final class RegionSeasonalWitnessGroupAdjuster: SeasonalWitnessGroupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SeasonalWitnessGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSeasonalWitnessGroupAdjuster: SeasonalWitnessGroupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalWitnessGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSeasonalWitnessGroupAdjuster: SeasonalWitnessGroupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalWitnessGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingSeasonalWitnessGroupAdjuster: SeasonalWitnessGroupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalWitnessGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSeasonalWitnessGroupAdjuster: SeasonalWitnessGroupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalWitnessGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal witness group steps in order and keeps a trace of each.
    final class SeasonalWitnessGroupEngine {
        var steps: [any SeasonalWitnessGroupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalWitnessGroupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalWitnessGroup) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalWitnessGroupModifier = steps[index]
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

        func evaluateAll(_ items: [SeasonalWitnessGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalWitnessGroupEngine() -> SeasonalWitnessGroupEngine {
        return SeasonalWitnessGroupEngine(
            steps: [
                RegionSeasonalWitnessGroupAdjuster(factors: ["north": 1.09, "south": 0.96, "retail": 0.89]),
                PercentSeasonalWitnessGroupAdjuster(percent: 6.7),
                MinimumSeasonalWitnessGroupAdjuster(minimum: 24.0),
                RoundingSeasonalWitnessGroupAdjuster(step: 0.5),
                TieredSeasonalWitnessGroupAdjuster(bounds: [1497.0, 3565.0, 9645.0], rates: [0.81, 1.1, 1.1]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 7340.4
        )
    }
}
