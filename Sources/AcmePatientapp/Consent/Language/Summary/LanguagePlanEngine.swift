import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language plan calculation.
    protocol LanguagePlanFactor {
        func describe() -> String
        func adjust(_ item: LanguagePlan, value: Double) -> Double
    }

    final class CapLanguagePlanAdjuster: LanguagePlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguagePlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumLanguagePlanAdjuster: LanguagePlanFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguagePlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLanguagePlanAdjuster: LanguagePlanFactor {
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

        func adjust(_ item: LanguagePlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LanguagePlanGraceDaysOffsetAdjuster: LanguagePlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LanguagePlan, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    /// Runs the language plan steps in order and keeps a trace of each.
    final class LanguagePlanEngine {
        var steps: [any LanguagePlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguagePlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguagePlan) -> Double {
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

        func evaluateAll(_ items: [LanguagePlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguagePlanEngine(_ flags: Kit.Flags.Registry) -> LanguagePlanEngine {
        return LanguagePlanEngine(
            steps: [
                CapLanguagePlanAdjuster(cap: 21828.0),
                MinimumLanguagePlanAdjuster(minimum: 8.1),
                FlaggedLanguagePlanAdjuster(flags: flags, flag: "language-plan-batched", percent: -1.2),
                LanguagePlanGraceDaysOffsetAdjuster(weight: 0.65),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 45676.7
        )
    }
}
