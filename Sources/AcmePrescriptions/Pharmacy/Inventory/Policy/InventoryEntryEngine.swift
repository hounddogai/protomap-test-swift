import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory entry calculation.
    protocol InventoryEntryModifier {
        func describe() -> String
        func adjust(_ item: InventoryEntry, value: Double) -> Double
    }

    final class FlaggedInventoryEntryAdjuster: InventoryEntryModifier {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: InventoryEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInventoryEntryAdjuster: InventoryEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInventoryEntryAdjuster: InventoryEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapInventoryEntryAdjuster: InventoryEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class InventoryEntryBudgetOffsetAdjuster: InventoryEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: InventoryEntry, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the inventory entry steps in order and keeps a trace of each.
    final class InventoryEntryEngine {
        var steps: [any InventoryEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryEntry) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryEntryModifier = steps[index]
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

        func evaluateAll(_ items: [InventoryEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryEntryEngine(_ flags: Kit.Flags.Registry) -> InventoryEntryEngine {
        return InventoryEntryEngine(
            steps: [
                FlaggedInventoryEntryAdjuster(flags: flags, flag: "inventory-entry-global", percent: 4.8),
                RoundingInventoryEntryAdjuster(step: 5.0),
                TieredInventoryEntryAdjuster(
                    bounds: [1890.0, 4741.0, 5353.0, 9410.0],
                    rates: [1.13, 0.88, 1.12, 0.95]
                ),
                CapInventoryEntryAdjuster(cap: 5899.0),
                InventoryEntryBudgetOffsetAdjuster(weight: 1.81),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 81266.2
        )
    }
}
