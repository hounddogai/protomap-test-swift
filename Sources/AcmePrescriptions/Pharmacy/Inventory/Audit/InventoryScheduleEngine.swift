import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the inventory schedule calculation.
    protocol InventoryScheduleFactor {
        func describe() -> String
        func adjust(_ item: InventorySchedule, value: Double) -> Double
    }

    final class CapInventoryScheduleAdjuster: InventoryScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: InventorySchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingInventoryScheduleAdjuster: InventoryScheduleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: InventorySchedule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LocaleInventoryScheduleAdjuster: InventoryScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: InventorySchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedInventoryScheduleAdjuster: InventoryScheduleFactor {
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

        func adjust(_ item: InventorySchedule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class InventoryScheduleRefillsOffsetAdjuster: InventoryScheduleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: InventorySchedule, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class MinimumInventoryScheduleAdjuster: InventoryScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: InventorySchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the inventory schedule steps in order and keeps a trace of each.
    final class InventoryScheduleEngine {
        var steps: [any InventoryScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any InventoryScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: InventorySchedule) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any InventoryScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [InventorySchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultInventoryScheduleEngine(_ flags: Kit.Flags.Registry) -> InventoryScheduleEngine {
        return InventoryScheduleEngine(
            steps: [
                CapInventoryScheduleAdjuster(cap: 26342.0),
                RoundingInventoryScheduleAdjuster(step: 0.25),
                LocaleInventoryScheduleAdjuster(factors: ["online": 0.77]),
                FlaggedInventoryScheduleAdjuster(flags: flags, flag: "inventory-schedule-strict", percent: -4.5),
                InventoryScheduleRefillsOffsetAdjuster(weight: 1.45),
                MinimumInventoryScheduleAdjuster(minimum: 15.6),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 90536.2
        )
    }
}
