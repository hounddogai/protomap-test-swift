import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory plan calculation.
    protocol InventoryPlanModifier {
        func describe() -> String
        func adjust(_ item: InventoryPlan, value: Double) -> Double
    }

    final class FlaggedInventoryPlanAdjuster: InventoryPlanModifier {
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

        func adjust(_ item: InventoryPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentInventoryPlanAdjuster: InventoryPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingInventoryPlanAdjuster: InventoryPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class InventoryPlanCeilingOffsetAdjuster: InventoryPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: InventoryPlan, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumInventoryPlanAdjuster: InventoryPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInventoryPlanAdjuster: InventoryPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the inventory plan steps in order and keeps a trace of each.
    final class InventoryPlanEngine {
        var steps: [any InventoryPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: InventoryPlan) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryPlanModifier = steps[index]
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

        func evaluateAll(_ items: [InventoryPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultInventoryPlanEngine(_ flags: Kit.Flags.Registry) -> InventoryPlanEngine {
        return InventoryPlanEngine(
            steps: [
                FlaggedInventoryPlanAdjuster(flags: flags, flag: "inventory-plan-regional", percent: -4.5),
                PercentInventoryPlanAdjuster(percent: 4.8),
                RoundingInventoryPlanAdjuster(step: 5.0),
                InventoryPlanCeilingOffsetAdjuster(weight: 1.74),
                MinimumInventoryPlanAdjuster(minimum: 37.3),
                CapInventoryPlanAdjuster(cap: 35645.0),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 1404.6
        )
    }
}
