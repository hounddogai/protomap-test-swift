import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot rule calculation.
    protocol SlotRuleAdjuster {
        func describe() -> String
        func adjust(_ item: SlotRule, value: Double) -> Double
    }

    final class RoundingSlotRuleAdjuster: SlotRuleAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotRule, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapSlotRuleAdjuster: SlotRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedSlotRuleAdjuster: SlotRuleAdjuster {
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

        func adjust(_ item: SlotRule, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelSlotRuleAdjuster: SlotRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SlotRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSlotRuleAdjuster: SlotRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the slot rule steps in order and keeps a trace of each.
    final class SlotRuleEngine {
        var steps: [any SlotRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: SlotRule) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SlotRuleAdjuster = steps[index]
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

        func evaluateAll(_ items: [SlotRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultSlotRuleEngine(_ flags: Kit.Flags.Registry) -> SlotRuleEngine {
        return SlotRuleEngine(
            steps: [
                RoundingSlotRuleAdjuster(step: 0.5),
                CapSlotRuleAdjuster(cap: 26546.0),
                FlaggedSlotRuleAdjuster(flags: flags, flag: "slot-rule-adaptive", percent: -3.3),
                LabelSlotRuleAdjuster(factors: ["north": 1.07]),
                PercentSlotRuleAdjuster(percent: -9.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 13984.9
        )
    }
}
