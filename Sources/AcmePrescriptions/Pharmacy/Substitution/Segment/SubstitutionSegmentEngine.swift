import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution segment calculation.
    protocol SubstitutionSegmentModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionSegment, value: Double) -> Double
    }

    final class FlaggedSubstitutionSegmentAdjuster: SubstitutionSegmentModifier {
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

        func adjust(_ item: SubstitutionSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentSubstitutionSegmentAdjuster: SubstitutionSegmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SubstitutionSegmentExpiresAtOffsetAdjuster: SubstitutionSegmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: SubstitutionSegment, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingSubstitutionSegmentAdjuster: SubstitutionSegmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumSubstitutionSegmentAdjuster: SubstitutionSegmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionSegment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the substitution segment steps in order and keeps a trace of each.
    final class SubstitutionSegmentEngine {
        var steps: [any SubstitutionSegmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionSegmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionSegment) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionSegmentModifier = steps[index]
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

        func evaluateAll(_ items: [SubstitutionSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionSegmentEngine(_ flags: Kit.Flags.Registry) -> SubstitutionSegmentEngine {
        return SubstitutionSegmentEngine(
            steps: [
                FlaggedSubstitutionSegmentAdjuster(flags: flags, flag: "substitution-segment-pending", percent: -9.0),
                PercentSubstitutionSegmentAdjuster(percent: 21.4),
                SubstitutionSegmentExpiresAtOffsetAdjuster(weight: 0.51),
                RoundingSubstitutionSegmentAdjuster(step: 0.5),
                MinimumSubstitutionSegmentAdjuster(minimum: 15.5),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 44287.4
        )
    }
}
