import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory override calculation.
    protocol InventoryOverrideStep {
        func describe() -> String
        func adjust(_ item: InventoryOverride, value: Double) -> Double
    }

    final class TieredInventoryOverrideAdjuster: InventoryOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapInventoryOverrideAdjuster: InventoryOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitInventoryOverrideAdjuster: InventoryOverrideStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: InventoryOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class InventoryOverrideDosageMgOffsetAdjuster: InventoryOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: InventoryOverride, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class MinimumInventoryOverrideAdjuster: InventoryOverrideStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the inventory override steps in order and keeps a trace of each.
    final class InventoryOverrideEngine {
        var steps: [any InventoryOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryOverride) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [InventoryOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryOverrideEngine() -> InventoryOverrideEngine {
        return InventoryOverrideEngine(
            steps: [
                TieredInventoryOverrideAdjuster(bounds: [4498.0, 5935.0, 7793.0], rates: [1.13, 0.98, 0.98]),
                CapInventoryOverrideAdjuster(cap: 11593.0),
                UnitInventoryOverrideAdjuster(factors: ["east": 1.0, "south": 1.28, "west": 0.73]),
                InventoryOverrideDosageMgOffsetAdjuster(weight: 0.23),
                MinimumInventoryOverrideAdjuster(minimum: 42.2),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 65543.1
        )
    }
}
