import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default disclosure profile calculation.
    protocol DefaultDisclosureProfileModifier {
        func describe() -> String
        func adjust(_ item: DefaultDisclosureProfile, value: Double) -> Double
    }

    final class MinimumDefaultDisclosureProfileAdjuster: DefaultDisclosureProfileModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultDisclosureProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDefaultDisclosureProfileAdjuster: DefaultDisclosureProfileModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DefaultDisclosureProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDefaultDisclosureProfileAdjuster: DefaultDisclosureProfileModifier {
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

        func adjust(_ item: DefaultDisclosureProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultDisclosureProfileUpdatedAtOffsetAdjuster: DefaultDisclosureProfileModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DefaultDisclosureProfile, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the default disclosure profile steps in order and keeps a trace of each.
    final class DefaultDisclosureProfileEngine {
        var steps: [any DefaultDisclosureProfileModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDisclosureProfileModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultDisclosureProfile) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultDisclosureProfileModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultDisclosureProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultDisclosureProfileEngine(_ flags: Kit.Flags.Registry) -> DefaultDisclosureProfileEngine {
        return DefaultDisclosureProfileEngine(
            steps: [
                MinimumDefaultDisclosureProfileAdjuster(minimum: 21.4),
                RoundingDefaultDisclosureProfileAdjuster(step: 1.0),
                FlaggedDefaultDisclosureProfileAdjuster(
                    flags: flags,
                    flag: "default-disclosure-profile-fallback",
                    percent: -1.3
                ),
                DefaultDisclosureProfileUpdatedAtOffsetAdjuster(weight: 1.21),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 53753.2
        )
    }
}
