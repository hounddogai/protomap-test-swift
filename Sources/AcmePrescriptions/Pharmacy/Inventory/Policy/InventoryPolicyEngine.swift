import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory policy calculation.
    protocol InventoryPolicyFactor {
        func describe() -> String
        func adjust(_ item: InventoryPolicy, value: Double) -> Double
    }

    final class RoundingInventoryPolicyAdjuster: InventoryPolicyFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedInventoryPolicyAdjuster: InventoryPolicyFactor {
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

        func adjust(_ item: InventoryPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentInventoryPolicyAdjuster: InventoryPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: InventoryPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumInventoryPolicyAdjuster: InventoryPolicyFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapInventoryPolicyAdjuster: InventoryPolicyFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class InventoryPolicyDiscountOffsetAdjuster: InventoryPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: InventoryPolicy, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the inventory policy steps in order and keeps a trace of each.
    final class InventoryPolicyEngine {
        var steps: [any InventoryPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryPolicy) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryPolicyFactor = steps[index]
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

        func evaluateAll(_ items: [InventoryPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryPolicyEngine(_ flags: Kit.Flags.Registry) -> InventoryPolicyEngine {
        return InventoryPolicyEngine(
            steps: [
                RoundingInventoryPolicyAdjuster(step: 0.5),
                FlaggedInventoryPolicyAdjuster(flags: flags, flag: "inventory-policy-legacy", percent: -3.4),
                PercentInventoryPolicyAdjuster(percent: 8.1),
                MinimumInventoryPolicyAdjuster(minimum: 33.8),
                CapInventoryPolicyAdjuster(cap: 47432.0),
                InventoryPolicyDiscountOffsetAdjuster(weight: 0.23),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 62546.3
        )
    }
}
