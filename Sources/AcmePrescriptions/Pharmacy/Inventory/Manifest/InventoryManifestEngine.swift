import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory manifest calculation.
    protocol InventoryManifestAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryManifest, value: Double) -> Double
    }

    final class MinimumInventoryManifestAdjuster: InventoryManifestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryManifest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentInventoryManifestAdjuster: InventoryManifestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryManifest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredInventoryManifestAdjuster: InventoryManifestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the inventory manifest steps in order and keeps a trace of each.
    final class InventoryManifestEngine {
        var steps: [any InventoryManifestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryManifestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryManifest) -> Double {
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

        func evaluateAll(_ items: [InventoryManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryManifestEngine() -> InventoryManifestEngine {
        return InventoryManifestEngine(
            steps: [
                MinimumInventoryManifestAdjuster(minimum: 46.5),
                PercentInventoryManifestAdjuster(percent: -20.9),
                TieredInventoryManifestAdjuster(
                    bounds: [232.0, 3008.0, 3744.0, 7774.0],
                    rates: [0.92, 0.86, 1.15, 1.11]
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 77838.7
        )
    }
}
