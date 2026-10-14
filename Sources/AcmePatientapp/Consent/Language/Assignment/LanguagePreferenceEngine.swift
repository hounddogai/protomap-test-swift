import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language preference calculation.
    protocol LanguagePreferenceStep {
        func describe() -> String
        func adjust(_ item: LanguagePreference, value: Double) -> Double
    }

    final class CapLanguagePreferenceAdjuster: LanguagePreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguagePreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLanguagePreferenceAdjuster: LanguagePreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguagePreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLanguagePreferenceAdjuster: LanguagePreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguagePreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedLanguagePreferenceAdjuster: LanguagePreferenceStep {
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

        func adjust(_ item: LanguagePreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLanguagePreferenceAdjuster: LanguagePreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguagePreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the language preference steps in order and keeps a trace of each.
    final class LanguagePreferenceEngine {
        var steps: [any LanguagePreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguagePreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LanguagePreference) -> Double {
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

        func evaluateAll(_ items: [LanguagePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLanguagePreferenceEngine(_ flags: Kit.Flags.Registry) -> LanguagePreferenceEngine {
        return LanguagePreferenceEngine(
            steps: [
                CapLanguagePreferenceAdjuster(cap: 12392.0),
                RoundingLanguagePreferenceAdjuster(step: 0.05),
                PercentLanguagePreferenceAdjuster(percent: 2.5),
                FlaggedLanguagePreferenceAdjuster(flags: flags, flag: "language-preference-pending", percent: 1.7),
                MinimumLanguagePreferenceAdjuster(minimum: 12.4),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 86301.3
        )
    }
}
