import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier preference calculation.
    protocol CourierPreferenceFactor {
        func describe() -> String
        func adjust(_ item: CourierPreference, value: Double) -> Double
    }

    final class CapCourierPreferenceAdjuster: CourierPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryCourierPreferenceAdjuster: CourierPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: CourierPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CourierPreferenceDiscountOffsetAdjuster: CourierPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: CourierPreference, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingCourierPreferenceAdjuster: CourierPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCourierPreferenceAdjuster: CourierPreferenceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCourierPreferenceAdjuster: CourierPreferenceFactor {
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

        func adjust(_ item: CourierPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier preference steps in order and keeps a trace of each.
    final class CourierPreferenceEngine {
        var steps: [any CourierPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierPreference) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [CourierPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierPreferenceEngine(_ flags: Kit.Flags.Registry) -> CourierPreferenceEngine {
        return CourierPreferenceEngine(
            steps: [
                CapCourierPreferenceAdjuster(cap: 2722.0),
                CountryCourierPreferenceAdjuster(factors: ["retail": 1.26, "central": 1.38]),
                CourierPreferenceDiscountOffsetAdjuster(weight: 1.69),
                RoundingCourierPreferenceAdjuster(step: 0.25),
                PercentCourierPreferenceAdjuster(percent: -7.4),
                FlaggedCourierPreferenceAdjuster(flags: flags, flag: "courier-preference-manual", percent: -3.7),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 75276.4
        )
    }
}
