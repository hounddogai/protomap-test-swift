import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the seasonal read group calculation.
    protocol SeasonalReadGroupAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double
    }

    final class RoundingSeasonalReadGroupAdjuster: SeasonalReadGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelSeasonalReadGroupAdjuster: SeasonalReadGroupAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapSeasonalReadGroupAdjuster: SeasonalReadGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SeasonalReadGroupScoreOffsetAdjuster: SeasonalReadGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumSeasonalReadGroupAdjuster: SeasonalReadGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalReadGroupAdjuster: SeasonalReadGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalReadGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal read group steps in order and keeps a trace of each.
    final class SeasonalReadGroupEngine {
        var steps: [any SeasonalReadGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalReadGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SeasonalReadGroup) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalReadGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalReadGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSeasonalReadGroupEngine() -> SeasonalReadGroupEngine {
        return SeasonalReadGroupEngine(
            steps: [
                RoundingSeasonalReadGroupAdjuster(step: 0.5),
                LabelSeasonalReadGroupAdjuster(factors: ["south": 1.16, "online": 0.79, "west": 1.15]),
                CapSeasonalReadGroupAdjuster(cap: 46757.0),
                SeasonalReadGroupScoreOffsetAdjuster(weight: 1.07),
                MinimumSeasonalReadGroupAdjuster(minimum: 28.9),
                TieredSeasonalReadGroupAdjuster(
                    bounds: [2179.0, 3497.0, 9165.0, 9761.0],
                    rates: [1.14, 1.07, 1.13, 1.16]
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 50902.6
        )
    }
}
