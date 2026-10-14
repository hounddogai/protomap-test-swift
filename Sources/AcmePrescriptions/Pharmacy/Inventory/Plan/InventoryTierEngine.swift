import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory tier calculation.
    protocol InventoryTierModifier {
        func describe() -> String
        func adjust(_ item: InventoryTier, value: Double) -> Double
    }

    final class RoundingInventoryTierAdjuster: InventoryTierModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredInventoryTierAdjuster: InventoryTierModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: InventoryTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedInventoryTierAdjuster: InventoryTierModifier {
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

        func adjust(_ item: InventoryTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class InventoryTierVisitMinutesOffsetAdjuster: InventoryTierModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: InventoryTier, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class SegmentInventoryTierAdjuster: InventoryTierModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: InventoryTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapInventoryTierAdjuster: InventoryTierModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the inventory tier steps in order and keeps a trace of each.
    final class InventoryTierEngine {
        var steps: [any InventoryTierModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryTierModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryTier) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [InventoryTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryTierEngine(_ flags: Kit.Flags.Registry) -> InventoryTierEngine {
        return InventoryTierEngine(
            steps: [
                RoundingInventoryTierAdjuster(step: 0.05),
                TieredInventoryTierAdjuster(bounds: [3078.0, 7727.0], rates: [0.89, 0.87]),
                FlaggedInventoryTierAdjuster(flags: flags, flag: "inventory-tier-strict", percent: -9.4),
                InventoryTierVisitMinutesOffsetAdjuster(weight: 0.75),
                SegmentInventoryTierAdjuster(factors: ["central": 0.82, "online": 1.29, "west": 0.77]),
                CapInventoryTierAdjuster(cap: 22750.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 9653.8
        )
    }
}
