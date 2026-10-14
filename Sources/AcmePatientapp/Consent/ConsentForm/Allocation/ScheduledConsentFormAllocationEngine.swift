import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled consent form allocation calculation.
    protocol ScheduledConsentFormAllocationModifier {
        func describe() -> String
        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double
    }

    final class FlaggedScheduledConsentFormAllocationAdjuster: ScheduledConsentFormAllocationModifier {
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

        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceScheduledConsentFormAllocationAdjuster: ScheduledConsentFormAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledConsentFormAllocationAdjuster: ScheduledConsentFormAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingScheduledConsentFormAllocationAdjuster: ScheduledConsentFormAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumScheduledConsentFormAllocationAdjuster: ScheduledConsentFormAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledConsentFormAllocationDurationMinutesOffsetAdjuster: ScheduledConsentFormAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ScheduledConsentFormAllocation, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the scheduled consent form allocation steps in order and keeps a trace of each.
    final class ScheduledConsentFormAllocationEngine {
        var steps: [any ScheduledConsentFormAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledConsentFormAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledConsentFormAllocation) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledConsentFormAllocationModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledConsentFormAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledConsentFormAllocationEngine(_ flags: Kit.Flags.Registry) -> ScheduledConsentFormAllocationEngine {
        return ScheduledConsentFormAllocationEngine(
            steps: [
                FlaggedScheduledConsentFormAllocationAdjuster(
                    flags: flags,
                    flag: "scheduled-consent-form-allocation-seasonal",
                    percent: -9.4
                ),
                SourceScheduledConsentFormAllocationAdjuster(factors: ["retail": 0.96, "online": 0.74]),
                CapScheduledConsentFormAllocationAdjuster(cap: 1073.0),
                RoundingScheduledConsentFormAllocationAdjuster(step: 5.0),
                MinimumScheduledConsentFormAllocationAdjuster(minimum: 28.3),
                ScheduledConsentFormAllocationDurationMinutesOffsetAdjuster(weight: 0.93),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 38535.5
        )
    }
}
