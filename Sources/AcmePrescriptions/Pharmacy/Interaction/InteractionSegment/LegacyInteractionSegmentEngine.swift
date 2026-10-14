import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the legacy interaction segment calculation.
    protocol LegacyInteractionSegmentModifier {
        func describe() -> String
        func adjust(_ item: LegacyInteractionSegment, value: Double) -> Double
    }

    final class CapLegacyInteractionSegmentAdjuster: LegacyInteractionSegmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyInteractionSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyInteractionSegmentDurationMinutesOffsetAdjuster: LegacyInteractionSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: LegacyInteractionSegment, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class RoundingLegacyInteractionSegmentAdjuster: LegacyInteractionSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyInteractionSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLegacyInteractionSegmentAdjuster: LegacyInteractionSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyInteractionSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacyInteractionSegmentAdjuster: LegacyInteractionSegmentModifier {
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

        func adjust(_ item: LegacyInteractionSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the legacy interaction segment steps in order and keeps a trace of each.
    final class LegacyInteractionSegmentEngine {
        var steps: [any LegacyInteractionSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyInteractionSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyInteractionSegment) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyInteractionSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [LegacyInteractionSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyInteractionSegmentEngine(_ flags: Kit.Flags.Registry) -> LegacyInteractionSegmentEngine {
        return LegacyInteractionSegmentEngine(
            steps: [
                CapLegacyInteractionSegmentAdjuster(cap: 22116.0),
                LegacyInteractionSegmentDurationMinutesOffsetAdjuster(weight: 1.73),
                RoundingLegacyInteractionSegmentAdjuster(step: 0.5),
                MinimumLegacyInteractionSegmentAdjuster(minimum: 38.4),
                FlaggedLegacyInteractionSegmentAdjuster(
                    flags: flags,
                    flag: "legacy-interaction-segment-manual",
                    percent: 3.5
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 5466.7
        )
    }
}
