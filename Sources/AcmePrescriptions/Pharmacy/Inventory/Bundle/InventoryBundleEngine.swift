import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory bundle calculation.
    protocol InventoryBundleFactor {
        func describe() -> String
        func adjust(_ item: InventoryBundle, value: Double) -> Double
    }

    final class MinimumInventoryBundleAdjuster: InventoryBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingInventoryBundleAdjuster: InventoryBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapInventoryBundleAdjuster: InventoryBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LocaleInventoryBundleAdjuster: InventoryBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: InventoryBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredInventoryBundleAdjuster: InventoryBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory bundle steps in order and keeps a trace of each.
    final class InventoryBundleEngine {
        var steps: [any InventoryBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryBundle) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [InventoryBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryBundleEngine() -> InventoryBundleEngine {
        return InventoryBundleEngine(
            steps: [
                MinimumInventoryBundleAdjuster(minimum: 32.6),
                RoundingInventoryBundleAdjuster(step: 0.1),
                CapInventoryBundleAdjuster(cap: 41317.0),
                LocaleInventoryBundleAdjuster(factors: ["south": 1.02, "online": 0.83, "east": 1.27]),
                TieredInventoryBundleAdjuster(bounds: [2784.0, 6583.0], rates: [1.01, 1.18]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 87404.7
        )
    }
}
