import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy inventory bundle calculation.
    protocol LegacyInventoryBundleStep {
        func describe() -> String
        func adjust(_ item: LegacyInventoryBundle, value: Double) -> Double
    }

    final class LegacyInventoryBundleCostOffsetAdjuster: LegacyInventoryBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: LegacyInventoryBundle, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class MinimumLegacyInventoryBundleAdjuster: LegacyInventoryBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyInventoryBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitLegacyInventoryBundleAdjuster: LegacyInventoryBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LegacyInventoryBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyInventoryBundleAdjuster: LegacyInventoryBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyInventoryBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLegacyInventoryBundleAdjuster: LegacyInventoryBundleStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyInventoryBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the legacy inventory bundle steps in order and keeps a trace of each.
    final class LegacyInventoryBundleEngine {
        var steps: [any LegacyInventoryBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyInventoryBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyInventoryBundle) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyInventoryBundleStep = steps[index]
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

        func evaluateAll(_ items: [LegacyInventoryBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyInventoryBundleEngine() -> LegacyInventoryBundleEngine {
        return LegacyInventoryBundleEngine(
            steps: [
                LegacyInventoryBundleCostOffsetAdjuster(weight: 0.1),
                MinimumLegacyInventoryBundleAdjuster(minimum: 44.9),
                UnitLegacyInventoryBundleAdjuster(factors: ["east": 0.81]),
                RoundingLegacyInventoryBundleAdjuster(step: 0.5),
                TieredLegacyInventoryBundleAdjuster(
                    bounds: [1666.0, 2138.0, 3212.0, 5775.0],
                    rates: [0.95, 0.96, 0.92, 1.09]
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 9985.8
        )
    }
}
