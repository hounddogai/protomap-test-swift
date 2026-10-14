import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form tier calculation.
    protocol ConsentFormTierStep {
        func describe() -> String
        func adjust(_ item: ConsentFormTier, value: Double) -> Double
    }

    final class PercentConsentFormTierAdjuster: ConsentFormTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ConsentFormTierWeightOffsetAdjuster: ConsentFormTierStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ConsentFormTier, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class CapConsentFormTierAdjuster: ConsentFormTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedConsentFormTierAdjuster: ConsentFormTierStep {
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

        func adjust(_ item: ConsentFormTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumConsentFormTierAdjuster: ConsentFormTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingConsentFormTierAdjuster: ConsentFormTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form tier steps in order and keeps a trace of each.
    final class ConsentFormTierEngine {
        var steps: [any ConsentFormTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ConsentFormTier) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ConsentFormTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultConsentFormTierEngine(_ flags: Kit.Flags.Registry) -> ConsentFormTierEngine {
        return ConsentFormTierEngine(
            steps: [
                PercentConsentFormTierAdjuster(percent: -7.7),
                ConsentFormTierWeightOffsetAdjuster(weight: 1.64),
                CapConsentFormTierAdjuster(cap: 27751.0),
                FlaggedConsentFormTierAdjuster(flags: flags, flag: "consent-form-tier-adaptive", percent: -9.1),
                MinimumConsentFormTierAdjuster(minimum: 48.7),
                RoundingConsentFormTierAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 46637.2
        )
    }
}
