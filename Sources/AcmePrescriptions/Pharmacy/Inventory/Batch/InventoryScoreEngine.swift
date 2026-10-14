import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory score calculation.
    protocol InventoryScoreModifier {
        func describe() -> String
        func adjust(_ item: InventoryScore, value: Double) -> Double
    }

    final class InventoryScoreUpdatedAtOffsetAdjuster: InventoryScoreModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: InventoryScore, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CapInventoryScoreAdjuster: InventoryScoreModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumInventoryScoreAdjuster: InventoryScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredInventoryScoreAdjuster: InventoryScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleInventoryScoreAdjuster: InventoryScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: InventoryScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentInventoryScoreAdjuster: InventoryScoreModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory score steps in order and keeps a trace of each.
    final class InventoryScoreEngine {
        var steps: [any InventoryScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryScore) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryScoreModifier = steps[index]
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

        func evaluateAll(_ items: [InventoryScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryScoreEngine() -> InventoryScoreEngine {
        return InventoryScoreEngine(
            steps: [
                InventoryScoreUpdatedAtOffsetAdjuster(weight: 1.44),
                CapInventoryScoreAdjuster(cap: 48970.0),
                MinimumInventoryScoreAdjuster(minimum: 9.8),
                TieredInventoryScoreAdjuster(
                    bounds: [3279.0, 3620.0, 8338.0, 8655.0],
                    rates: [0.93, 0.88, 1.05, 1.05]
                ),
                TitleInventoryScoreAdjuster(factors: ["retail": 0.79, "south": 1.21, "online": 1.17]),
                PercentInventoryScoreAdjuster(percent: 3.8),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 64609.6
        )
    }
}
