import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback courier slot calculation.
    protocol FallbackCourierSlotAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackCourierSlot, value: Double) -> Double
    }

    final class FlaggedFallbackCourierSlotAdjuster: FallbackCourierSlotAdjuster {
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

        func adjust(_ item: FallbackCourierSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackCourierSlotAdjuster: FallbackCourierSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCourierSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackCourierSlotEndsAtOffsetAdjuster: FallbackCourierSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: FallbackCourierSlot, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    /// Runs the fallback courier slot steps in order and keeps a trace of each.
    final class FallbackCourierSlotEngine {
        var steps: [any FallbackCourierSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCourierSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackCourierSlot) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCourierSlotAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackCourierSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackCourierSlotEngine(_ flags: Kit.Flags.Registry) -> FallbackCourierSlotEngine {
        return FallbackCourierSlotEngine(
            steps: [
                FlaggedFallbackCourierSlotAdjuster(flags: flags, flag: "fallback-courier-slot-global", percent: 4.4),
                RoundingFallbackCourierSlotAdjuster(step: 5.0),
                FallbackCourierSlotEndsAtOffsetAdjuster(weight: 0.42),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 67265.9
        )
    }
}
