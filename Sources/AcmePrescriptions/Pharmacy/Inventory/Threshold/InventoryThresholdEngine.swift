import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory threshold calculation.
    protocol InventoryThresholdStep {
        func describe() -> String
        func adjust(_ item: InventoryThreshold, value: Double) -> Double
    }

    final class CapInventoryThresholdAdjuster: InventoryThresholdStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class InventoryThresholdScoreOffsetAdjuster: InventoryThresholdStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: InventoryThreshold, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredInventoryThresholdAdjuster: InventoryThresholdStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingInventoryThresholdAdjuster: InventoryThresholdStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentInventoryThresholdAdjuster: InventoryThresholdStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory threshold steps in order and keeps a trace of each.
    final class InventoryThresholdEngine {
        var steps: [any InventoryThresholdStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryThresholdStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryThreshold) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryThresholdStep = steps[index]
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

        func evaluateAll(_ items: [InventoryThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryThresholdEngine() -> InventoryThresholdEngine {
        return InventoryThresholdEngine(
            steps: [
                CapInventoryThresholdAdjuster(cap: 40382.0),
                InventoryThresholdScoreOffsetAdjuster(weight: 0.95),
                TieredInventoryThresholdAdjuster(bounds: [299.0, 1917.0], rates: [0.94, 0.8]),
                RoundingInventoryThresholdAdjuster(step: 0.5),
                PercentInventoryThresholdAdjuster(percent: -17.2),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 74283.2
        )
    }
}
