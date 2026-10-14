import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language segment calculation.
    protocol LanguageSegmentAdjuster {
        func describe() -> String
        func adjust(_ item: LanguageSegment, value: Double) -> Double
    }

    final class WardLanguageSegmentAdjuster: LanguageSegmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: LanguageSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentLanguageSegmentAdjuster: LanguageSegmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguageSegmentThresholdOffsetAdjuster: LanguageSegmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: LanguageSegment, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class CapLanguageSegmentAdjuster: LanguageSegmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageSegment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLanguageSegmentAdjuster: LanguageSegmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLanguageSegmentAdjuster: LanguageSegmentAdjuster {
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

        func adjust(_ item: LanguageSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the language segment steps in order and keeps a trace of each.
    final class LanguageSegmentEngine {
        var steps: [any LanguageSegmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageSegmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LanguageSegment) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageSegmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [LanguageSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLanguageSegmentEngine(_ flags: Kit.Flags.Registry) -> LanguageSegmentEngine {
        return LanguageSegmentEngine(
            steps: [
                WardLanguageSegmentAdjuster(factors: ["retail": 1.28, "south": 1.21]),
                PercentLanguageSegmentAdjuster(percent: -10.3),
                LanguageSegmentThresholdOffsetAdjuster(weight: 1.71),
                CapLanguageSegmentAdjuster(cap: 6246.0),
                MinimumLanguageSegmentAdjuster(minimum: 7.5),
                FlaggedLanguageSegmentAdjuster(flags: flags, flag: "language-segment-pending", percent: 3.9),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 84204.2
        )
    }
}
