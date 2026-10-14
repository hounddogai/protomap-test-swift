import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the fallback shift segment calculation.
    protocol FallbackShiftSegmentModifier {
        func describe() -> String
        func adjust(_ item: FallbackShiftSegment, value: Double) -> Double
    }

    final class PercentFallbackShiftSegmentAdjuster: FallbackShiftSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackShiftSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackShiftSegmentAdjuster: FallbackShiftSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackShiftSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackShiftSegmentAdjuster: FallbackShiftSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackShiftSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FallbackShiftSegmentRatioOffsetAdjuster: FallbackShiftSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: FallbackShiftSegment, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class FlaggedFallbackShiftSegmentAdjuster: FallbackShiftSegmentModifier {
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

        func adjust(_ item: FallbackShiftSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback shift segment steps in order and keeps a trace of each.
    final class FallbackShiftSegmentEngine {
        var steps: [any FallbackShiftSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackShiftSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackShiftSegment) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [FallbackShiftSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackShiftSegmentEngine(_ flags: Kit.Flags.Registry) -> FallbackShiftSegmentEngine {
        return FallbackShiftSegmentEngine(
            steps: [
                PercentFallbackShiftSegmentAdjuster(percent: 6.2),
                MinimumFallbackShiftSegmentAdjuster(minimum: 40.0),
                RoundingFallbackShiftSegmentAdjuster(step: 0.1),
                FallbackShiftSegmentRatioOffsetAdjuster(weight: 0.65),
                FlaggedFallbackShiftSegmentAdjuster(
                    flags: flags,
                    flag: "fallback-shift-segment-batched",
                    percent: -6.2
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 72818.1
        )
    }
}
