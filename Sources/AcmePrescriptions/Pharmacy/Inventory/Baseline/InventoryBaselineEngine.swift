import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory baseline calculation.
    protocol InventoryBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: InventoryBaseline, value: Double) -> Double
    }

    final class RoundingInventoryBaselineAdjuster: InventoryBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventoryBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapInventoryBaselineAdjuster: InventoryBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventoryBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumInventoryBaselineAdjuster: InventoryBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventoryBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class InventoryBaselineCopayOffsetAdjuster: InventoryBaselineAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: InventoryBaseline, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class FlaggedInventoryBaselineAdjuster: InventoryBaselineAdjuster {
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

        func adjust(_ item: InventoryBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the inventory baseline steps in order and keeps a trace of each.
    final class InventoryBaselineEngine {
        var steps: [any InventoryBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: InventoryBaseline) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryBaselineAdjuster = steps[index]
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

        func evaluateAll(_ items: [InventoryBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultInventoryBaselineEngine(_ flags: Kit.Flags.Registry) -> InventoryBaselineEngine {
        return InventoryBaselineEngine(
            steps: [
                RoundingInventoryBaselineAdjuster(step: 0.1),
                CapInventoryBaselineAdjuster(cap: 35958.0),
                MinimumInventoryBaselineAdjuster(minimum: 45.9),
                InventoryBaselineCopayOffsetAdjuster(weight: 1.38),
                FlaggedInventoryBaselineAdjuster(flags: flags, flag: "inventory-baseline-default", percent: 1.1),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 95875.0
        )
    }
}
