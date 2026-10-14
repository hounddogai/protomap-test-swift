import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory request calculation.
    protocol InventoryRequestFactor {
        func describe() -> String
        func adjust(_ item: InventoryRequest, value: Double) -> Double
    }

    final class LocaleInventoryRequestAdjuster: InventoryRequestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: InventoryRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInventoryRequestAdjuster: InventoryRequestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingInventoryRequestAdjuster: InventoryRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapInventoryRequestAdjuster: InventoryRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the inventory request steps in order and keeps a trace of each.
    final class InventoryRequestEngine {
        var steps: [any InventoryRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: InventoryRequest) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryRequestFactor = steps[index]
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

        func evaluateAll(_ items: [InventoryRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultInventoryRequestEngine() -> InventoryRequestEngine {
        return InventoryRequestEngine(
            steps: [
                LocaleInventoryRequestAdjuster(factors: ["east": 0.79, "online": 0.94, "retail": 1.03]),
                TieredInventoryRequestAdjuster(bounds: [1270.0, 1580.0, 2075.0], rates: [1.07, 0.96, 1.16]),
                RoundingInventoryRequestAdjuster(step: 0.25),
                CapInventoryRequestAdjuster(cap: 27332.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 63599.9
        )
    }
}
