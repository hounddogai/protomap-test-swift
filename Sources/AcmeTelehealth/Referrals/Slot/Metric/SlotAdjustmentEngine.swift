import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot adjustment calculation.
    protocol SlotAdjustmentStep {
        func describe() -> String
        func adjust(_ item: SlotAdjustment, value: Double) -> Double
    }

    final class PercentSlotAdjustmentAdjuster: SlotAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedSlotAdjustmentAdjuster: SlotAdjustmentStep {
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

        func adjust(_ item: SlotAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSlotAdjustmentAdjuster: SlotAdjustmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the slot adjustment steps in order and keeps a trace of each.
    final class SlotAdjustmentEngine {
        var steps: [any SlotAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotAdjustment) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotAdjustmentStep = steps[index]
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

        func evaluateAll(_ items: [SlotAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotAdjustmentEngine(_ flags: Kit.Flags.Registry) -> SlotAdjustmentEngine {
        return SlotAdjustmentEngine(
            steps: [
                PercentSlotAdjustmentAdjuster(percent: -10.7),
                FlaggedSlotAdjustmentAdjuster(flags: flags, flag: "slot-adjustment-seasonal", percent: -4.0),
                CapSlotAdjustmentAdjuster(cap: 8322.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 23887.3
        )
    }
}
