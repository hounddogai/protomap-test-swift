import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory forecast calculation.
    protocol InventoryForecastFactor {
        func describe() -> String
        func adjust(_ item: InventoryForecast, value: Double) -> Double
    }

    final class LabelInventoryForecastAdjuster: InventoryForecastFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: InventoryForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapInventoryForecastAdjuster: InventoryForecastFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredInventoryForecastAdjuster: InventoryForecastFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory forecast steps in order and keeps a trace of each.
    final class InventoryForecastEngine {
        var steps: [any InventoryForecastFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryForecastFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryForecast) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [InventoryForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryForecastEngine() -> InventoryForecastEngine {
        return InventoryForecastEngine(
            steps: [
                LabelInventoryForecastAdjuster(factors: ["retail": 0.8]),
                CapInventoryForecastAdjuster(cap: 25574.0),
                TieredInventoryForecastAdjuster(bounds: [3873.0, 6187.0, 9765.0], rates: [1.19, 0.93, 0.88]),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 13826.5
        )
    }
}
