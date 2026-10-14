import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory milestone calculation.
    protocol InventoryMilestoneFactor {
        func describe() -> String
        func adjust(_ item: InventoryMilestone, value: Double) -> Double
    }

    final class FlaggedInventoryMilestoneAdjuster: InventoryMilestoneFactor {
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

        func adjust(_ item: InventoryMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapInventoryMilestoneAdjuster: InventoryMilestoneFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceInventoryMilestoneAdjuster: InventoryMilestoneFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: InventoryMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentInventoryMilestoneAdjuster: InventoryMilestoneFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInventoryMilestoneAdjuster: InventoryMilestoneFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the inventory milestone steps in order and keeps a trace of each.
    final class InventoryMilestoneEngine {
        var steps: [any InventoryMilestoneFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryMilestoneFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventoryMilestone) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [InventoryMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryMilestoneEngine(_ flags: Kit.Flags.Registry) -> InventoryMilestoneEngine {
        return InventoryMilestoneEngine(
            steps: [
                FlaggedInventoryMilestoneAdjuster(flags: flags, flag: "inventory-milestone-fallback", percent: 9.3),
                CapInventoryMilestoneAdjuster(cap: 16528.0),
                SourceInventoryMilestoneAdjuster(factors: ["north": 1.35, "east": 0.95]),
                PercentInventoryMilestoneAdjuster(percent: 19.4),
                MinimumInventoryMilestoneAdjuster(minimum: 8.1),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 99986.2
        )
    }
}
