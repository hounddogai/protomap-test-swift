import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the weighted eligibility slot calculation.
    protocol WeightedEligibilitySlotStep {
        func describe() -> String
        func adjust(_ item: WeightedEligibilitySlot, value: Double) -> Double
    }

    final class MinimumWeightedEligibilitySlotAdjuster: WeightedEligibilitySlotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedEligibilitySlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedEligibilitySlotAdjuster: WeightedEligibilitySlotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedEligibilitySlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedEligibilitySlotAdjuster: WeightedEligibilitySlotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedEligibilitySlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WeightedEligibilitySlotDurationMinutesOffsetAdjuster: WeightedEligibilitySlotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: WeightedEligibilitySlot, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class FlaggedWeightedEligibilitySlotAdjuster: WeightedEligibilitySlotStep {
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

        func adjust(_ item: WeightedEligibilitySlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted eligibility slot steps in order and keeps a trace of each.
    final class WeightedEligibilitySlotEngine {
        var steps: [any WeightedEligibilitySlotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedEligibilitySlotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedEligibilitySlot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedEligibilitySlotStep = steps[index]
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

        func evaluateAll(_ items: [WeightedEligibilitySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedEligibilitySlotEngine(_ flags: Kit.Flags.Registry) -> WeightedEligibilitySlotEngine {
        return WeightedEligibilitySlotEngine(
            steps: [
                MinimumWeightedEligibilitySlotAdjuster(minimum: 46.3),
                RoundingWeightedEligibilitySlotAdjuster(step: 5.0),
                CapWeightedEligibilitySlotAdjuster(cap: 8013.0),
                WeightedEligibilitySlotDurationMinutesOffsetAdjuster(weight: 0.67),
                FlaggedWeightedEligibilitySlotAdjuster(
                    flags: flags,
                    flag: "weighted-eligibility-slot-regional",
                    percent: 8.0
                ),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 99636.9
        )
    }
}
