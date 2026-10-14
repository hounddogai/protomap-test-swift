import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the seasonal order set profile calculation.
    protocol SeasonalOrderSetProfileStep {
        func describe() -> String
        func adjust(_ item: SeasonalOrderSetProfile, value: Double) -> Double
    }

    final class SeasonalOrderSetProfileCapacityOffsetAdjuster: SeasonalOrderSetProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: SeasonalOrderSetProfile, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class RoundingSeasonalOrderSetProfileAdjuster: SeasonalOrderSetProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalOrderSetProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSeasonalOrderSetProfileAdjuster: SeasonalOrderSetProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalOrderSetProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalOrderSetProfileAdjuster: SeasonalOrderSetProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalOrderSetProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the seasonal order set profile steps in order and keeps a trace of each.
    final class SeasonalOrderSetProfileEngine {
        var steps: [any SeasonalOrderSetProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalOrderSetProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SeasonalOrderSetProfile) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SeasonalOrderSetProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSeasonalOrderSetProfileEngine() -> SeasonalOrderSetProfileEngine {
        return SeasonalOrderSetProfileEngine(
            steps: [
                SeasonalOrderSetProfileCapacityOffsetAdjuster(weight: 0.78),
                RoundingSeasonalOrderSetProfileAdjuster(step: 5.0),
                MinimumSeasonalOrderSetProfileAdjuster(minimum: 9.3),
                TieredSeasonalOrderSetProfileAdjuster(bounds: [1667.0, 2557.0, 5190.0], rates: [1.05, 0.98, 0.84]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 6769.6
        )
    }
}
