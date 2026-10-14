import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual isolation preference calculation.
    protocol ManualIsolationPreferenceModifier {
        func describe() -> String
        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double
    }

    final class CountryManualIsolationPreferenceAdjuster: ManualIsolationPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredManualIsolationPreferenceAdjuster: ManualIsolationPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentManualIsolationPreferenceAdjuster: ManualIsolationPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualIsolationPreferenceAdjuster: ManualIsolationPreferenceModifier {
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

        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualIsolationPreferenceAdjuster: ManualIsolationPreferenceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumManualIsolationPreferenceAdjuster: ManualIsolationPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualIsolationPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual isolation preference steps in order and keeps a trace of each.
    final class ManualIsolationPreferenceEngine {
        var steps: [any ManualIsolationPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualIsolationPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualIsolationPreference) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualIsolationPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [ManualIsolationPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualIsolationPreferenceEngine(_ flags: Kit.Flags.Registry) -> ManualIsolationPreferenceEngine {
        return ManualIsolationPreferenceEngine(
            steps: [
                CountryManualIsolationPreferenceAdjuster(factors: ["north": 1.29, "east": 1.3]),
                TieredManualIsolationPreferenceAdjuster(
                    bounds: [6447.0, 6668.0, 8080.0, 8220.0],
                    rates: [0.99, 0.92, 0.96, 1.07]
                ),
                PercentManualIsolationPreferenceAdjuster(percent: -3.5),
                FlaggedManualIsolationPreferenceAdjuster(
                    flags: flags,
                    flag: "manual-isolation-preference-capped",
                    percent: 5.8
                ),
                CapManualIsolationPreferenceAdjuster(cap: 45904.0),
                MinimumManualIsolationPreferenceAdjuster(minimum: 18.5),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 67838.7
        )
    }
}
