import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot summary calculation.
    protocol SlotSummaryAdjuster {
        func describe() -> String
        func adjust(_ item: SlotSummary, value: Double) -> Double
    }

    final class FlaggedSlotSummaryAdjuster: SlotSummaryAdjuster {
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

        func adjust(_ item: SlotSummary, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSlotSummaryAdjuster: SlotSummaryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SlotSummaryPriorityOffsetAdjuster: SlotSummaryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: SlotSummary, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class CapSlotSummaryAdjuster: SlotSummaryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CategorySlotSummaryAdjuster: SlotSummaryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: SlotSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the slot summary steps in order and keeps a trace of each.
    final class SlotSummaryEngine {
        var steps: [any SlotSummaryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotSummaryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SlotSummary) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotSummaryAdjuster = steps[index]
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

        func evaluateAll(_ items: [SlotSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSlotSummaryEngine(_ flags: Kit.Flags.Registry) -> SlotSummaryEngine {
        return SlotSummaryEngine(
            steps: [
                FlaggedSlotSummaryAdjuster(flags: flags, flag: "slot-summary-tiered", percent: 4.4),
                PercentSlotSummaryAdjuster(percent: 8.5),
                SlotSummaryPriorityOffsetAdjuster(weight: 1.04),
                CapSlotSummaryAdjuster(cap: 5882.0),
                CategorySlotSummaryAdjuster(factors: ["east": 1.21, "central": 1.33]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 40316.1
        )
    }
}
