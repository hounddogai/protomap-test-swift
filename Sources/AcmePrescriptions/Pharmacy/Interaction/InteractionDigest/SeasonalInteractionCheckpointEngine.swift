import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the seasonal interaction checkpoint calculation.
    protocol SeasonalInteractionCheckpointStep {
        func describe() -> String
        func adjust(_ item: SeasonalInteractionCheckpoint, value: Double) -> Double
    }

    final class PercentSeasonalInteractionCheckpointAdjuster: SeasonalInteractionCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalInteractionCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategorySeasonalInteractionCheckpointAdjuster: SeasonalInteractionCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: SeasonalInteractionCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredSeasonalInteractionCheckpointAdjuster: SeasonalInteractionCheckpointStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalInteractionCheckpoint, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SeasonalInteractionCheckpointAmountOffsetAdjuster: SeasonalInteractionCheckpointStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: SeasonalInteractionCheckpoint, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the seasonal interaction checkpoint steps in order and keeps a trace of each.
    final class SeasonalInteractionCheckpointEngine {
        var steps: [any SeasonalInteractionCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalInteractionCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalInteractionCheckpoint) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [SeasonalInteractionCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalInteractionCheckpointEngine() -> SeasonalInteractionCheckpointEngine {
        return SeasonalInteractionCheckpointEngine(
            steps: [
                PercentSeasonalInteractionCheckpointAdjuster(percent: 5.4),
                CategorySeasonalInteractionCheckpointAdjuster(factors: ["west": 0.79, "east": 1.11, "retail": 0.84]),
                TieredSeasonalInteractionCheckpointAdjuster(bounds: [2624.0, 7053.0], rates: [1.06, 1.07]),
                SeasonalInteractionCheckpointAmountOffsetAdjuster(weight: 0.31),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 54866.2
        )
    }
}
