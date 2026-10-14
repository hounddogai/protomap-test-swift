import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy inventory group calculation.
    protocol LegacyInventoryGroupAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyInventoryGroup, value: Double) -> Double
    }

    final class CapLegacyInventoryGroupAdjuster: LegacyInventoryGroupAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyInventoryGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyInventoryGroupVersionOffsetAdjuster: LegacyInventoryGroupAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: LegacyInventoryGroup, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class MinimumLegacyInventoryGroupAdjuster: LegacyInventoryGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyInventoryGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLegacyInventoryGroupAdjuster: LegacyInventoryGroupAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyInventoryGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingLegacyInventoryGroupAdjuster: LegacyInventoryGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyInventoryGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy inventory group steps in order and keeps a trace of each.
    final class LegacyInventoryGroupEngine {
        var steps: [any LegacyInventoryGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyInventoryGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacyInventoryGroup) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [LegacyInventoryGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacyInventoryGroupEngine() -> LegacyInventoryGroupEngine {
        return LegacyInventoryGroupEngine(
            steps: [
                CapLegacyInventoryGroupAdjuster(cap: 14452.0),
                LegacyInventoryGroupVersionOffsetAdjuster(weight: 1.11),
                MinimumLegacyInventoryGroupAdjuster(minimum: 30.0),
                TieredLegacyInventoryGroupAdjuster(
                    bounds: [1527.0, 2138.0, 2325.0, 6585.0],
                    rates: [0.92, 1.1, 1.12, 0.99]
                ),
                RoundingLegacyInventoryGroupAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 66321.0
        )
    }
}
