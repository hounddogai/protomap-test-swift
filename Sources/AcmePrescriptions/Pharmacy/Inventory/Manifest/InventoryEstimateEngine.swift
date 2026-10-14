import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory estimate calculation.
    protocol InventoryEstimateModifier {
        func describe() -> String
        func adjust(_ item: InventoryEstimate, value: Double) -> Double
    }

    final class PercentInventoryEstimateAdjuster: InventoryEstimateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInventoryEstimateAdjuster: InventoryEstimateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WardInventoryEstimateAdjuster: InventoryEstimateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: InventoryEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingInventoryEstimateAdjuster: InventoryEstimateModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryEstimate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class InventoryEstimateFloorValueOffsetAdjuster: InventoryEstimateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: InventoryEstimate, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredInventoryEstimateAdjuster: InventoryEstimateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory estimate steps in order and keeps a trace of each.
    final class InventoryEstimateEngine {
        var steps: [any InventoryEstimateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryEstimateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryEstimate) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [InventoryEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryEstimateEngine() -> InventoryEstimateEngine {
        return InventoryEstimateEngine(
            steps: [
                PercentInventoryEstimateAdjuster(percent: 7.4),
                MinimumInventoryEstimateAdjuster(minimum: 29.1),
                WardInventoryEstimateAdjuster(factors: ["central": 0.86, "retail": 1.22, "west": 0.73]),
                RoundingInventoryEstimateAdjuster(step: 0.05),
                InventoryEstimateFloorValueOffsetAdjuster(weight: 1.36),
                TieredInventoryEstimateAdjuster(bounds: [1218.0, 6656.0], rates: [0.96, 1.18]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 40633.2
        )
    }
}
