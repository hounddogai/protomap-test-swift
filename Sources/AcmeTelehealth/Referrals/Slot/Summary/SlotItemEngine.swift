import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot item calculation.
    protocol SlotItemFactor {
        func describe() -> String
        func adjust(_ item: SlotItem, value: Double) -> Double
    }

    final class FlaggedSlotItemAdjuster: SlotItemFactor {
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

        func adjust(_ item: SlotItem, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSlotItemAdjuster: SlotItemFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotItem, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredSlotItemAdjuster: SlotItemFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SlotItem, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentSlotItemAdjuster: SlotItemFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotItem, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumSlotItemAdjuster: SlotItemFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotItem, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the slot item steps in order and keeps a trace of each.
    final class SlotItemEngine {
        var steps: [any SlotItemFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotItemFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotItem) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotItemFactor = steps[index]
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

        func evaluateAll(_ items: [SlotItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotItemEngine(_ flags: Kit.Flags.Registry) -> SlotItemEngine {
        return SlotItemEngine(
            steps: [
                FlaggedSlotItemAdjuster(flags: flags, flag: "slot-item-scheduled", percent: 7.6),
                RoundingSlotItemAdjuster(step: 0.1),
                TieredSlotItemAdjuster(bounds: [398.0, 846.0], rates: [1.1, 1.15]),
                PercentSlotItemAdjuster(percent: 1.1),
                MinimumSlotItemAdjuster(minimum: 48.7),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 75874.1
        )
    }
}
