import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the slot request calculation.
    protocol SlotRequestFactor {
        func describe() -> String
        func adjust(_ item: SlotRequest, value: Double) -> Double
    }

    final class RoundingSlotRequestAdjuster: SlotRequestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SlotRequest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSlotRequestAdjuster: SlotRequestFactor {
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

        func adjust(_ item: SlotRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSlotRequestAdjuster: SlotRequestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SlotRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SlotRequestBudgetOffsetAdjuster: SlotRequestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: SlotRequest, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class MinimumSlotRequestAdjuster: SlotRequestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SlotRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSlotRequestAdjuster: SlotRequestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SlotRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the slot request steps in order and keeps a trace of each.
    final class SlotRequestEngine {
        var steps: [any SlotRequestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SlotRequestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SlotRequest) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [SlotRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSlotRequestEngine(_ flags: Kit.Flags.Registry) -> SlotRequestEngine {
        return SlotRequestEngine(
            steps: [
                RoundingSlotRequestAdjuster(step: 0.1),
                FlaggedSlotRequestAdjuster(flags: flags, flag: "slot-request-default", percent: 1.5),
                PercentSlotRequestAdjuster(percent: 13.4),
                SlotRequestBudgetOffsetAdjuster(weight: 1.12),
                MinimumSlotRequestAdjuster(minimum: 46.5),
                CapSlotRequestAdjuster(cap: 17747.0),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 92257.8
        )
    }
}
