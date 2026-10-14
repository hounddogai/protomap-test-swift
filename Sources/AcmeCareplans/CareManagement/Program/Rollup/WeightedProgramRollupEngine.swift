import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted program rollup calculation.
    protocol WeightedProgramRollupFactor {
        func describe() -> String
        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double
    }

    final class PercentWeightedProgramRollupAdjuster: WeightedProgramRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WeightedProgramRollupUpdatedAtOffsetAdjuster: WeightedProgramRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class TieredWeightedProgramRollupAdjuster: WeightedProgramRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumWeightedProgramRollupAdjuster: WeightedProgramRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionWeightedProgramRollupAdjuster: WeightedProgramRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWeightedProgramRollupAdjuster: WeightedProgramRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedProgramRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted program rollup steps in order and keeps a trace of each.
    final class WeightedProgramRollupEngine {
        var steps: [any WeightedProgramRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedProgramRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedProgramRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedProgramRollupFactor = steps[index]
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

        func evaluateAll(_ items: [WeightedProgramRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedProgramRollupEngine() -> WeightedProgramRollupEngine {
        return WeightedProgramRollupEngine(
            steps: [
                PercentWeightedProgramRollupAdjuster(percent: 7.7),
                WeightedProgramRollupUpdatedAtOffsetAdjuster(weight: 1.15),
                TieredWeightedProgramRollupAdjuster(bounds: [505.0, 4269.0, 9919.0], rates: [1.04, 1.16, 0.89]),
                MinimumWeightedProgramRollupAdjuster(minimum: 25.0),
                RegionWeightedProgramRollupAdjuster(factors: ["east": 0.98, "north": 1.36]),
                RoundingWeightedProgramRollupAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 13373.1
        )
    }
}
