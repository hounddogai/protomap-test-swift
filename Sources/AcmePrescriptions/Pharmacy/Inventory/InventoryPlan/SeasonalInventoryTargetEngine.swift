import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal inventory target calculation.
    protocol SeasonalInventoryTargetAdjuster {
        func describe() -> String
        func adjust(_ item: SeasonalInventoryTarget, value: Double) -> Double
    }

    final class TieredSeasonalInventoryTargetAdjuster: SeasonalInventoryTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalInventoryTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalInventoryTargetUpdatedAtOffsetAdjuster: SeasonalInventoryTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: SeasonalInventoryTarget, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TitleSeasonalInventoryTargetAdjuster: SeasonalInventoryTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: SeasonalInventoryTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSeasonalInventoryTargetAdjuster: SeasonalInventoryTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalInventoryTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSeasonalInventoryTargetAdjuster: SeasonalInventoryTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalInventoryTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the seasonal inventory target steps in order and keeps a trace of each.
    final class SeasonalInventoryTargetEngine {
        var steps: [any SeasonalInventoryTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalInventoryTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalInventoryTarget) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalInventoryTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [SeasonalInventoryTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalInventoryTargetEngine() -> SeasonalInventoryTargetEngine {
        return SeasonalInventoryTargetEngine(
            steps: [
                TieredSeasonalInventoryTargetAdjuster(bounds: [2611.0, 5170.0], rates: [1.09, 1.17]),
                SeasonalInventoryTargetUpdatedAtOffsetAdjuster(weight: 1.91),
                TitleSeasonalInventoryTargetAdjuster(factors: ["retail": 1.32, "central": 0.82, "east": 1.32]),
                MinimumSeasonalInventoryTargetAdjuster(minimum: 3.8),
                CapSeasonalInventoryTargetAdjuster(cap: 11193.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 53496.0
        )
    }
}
