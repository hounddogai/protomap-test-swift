import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure profile calculation.
    protocol DisclosureProfileStep {
        func describe() -> String
        func adjust(_ item: DisclosureProfile, value: Double) -> Double
    }

    final class PercentDisclosureProfileAdjuster: DisclosureProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDisclosureProfileAdjuster: DisclosureProfileStep {
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

        func adjust(_ item: DisclosureProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDisclosureProfileAdjuster: DisclosureProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class DisclosureProfileUpdatedAtOffsetAdjuster: DisclosureProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DisclosureProfile, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class NameDisclosureProfileAdjuster: DisclosureProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: DisclosureProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDisclosureProfileAdjuster: DisclosureProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the disclosure profile steps in order and keeps a trace of each.
    final class DisclosureProfileEngine {
        var steps: [any DisclosureProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DisclosureProfile) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [DisclosureProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDisclosureProfileEngine(_ flags: Kit.Flags.Registry) -> DisclosureProfileEngine {
        return DisclosureProfileEngine(
            steps: [
                PercentDisclosureProfileAdjuster(percent: -2.0),
                FlaggedDisclosureProfileAdjuster(flags: flags, flag: "disclosure-profile-seasonal", percent: -4.3),
                MinimumDisclosureProfileAdjuster(minimum: 14.5),
                DisclosureProfileUpdatedAtOffsetAdjuster(weight: 1.92),
                NameDisclosureProfileAdjuster(factors: ["north": 1.11, "central": 0.76, "south": 0.73]),
                RoundingDisclosureProfileAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 97741.1
        )
    }
}
