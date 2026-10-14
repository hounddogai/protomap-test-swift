import AcmePlatform
import Foundation

extension Consent {
    /// One step of the default witness preference calculation.
    protocol DefaultWitnessPreferenceStep {
        func describe() -> String
        func adjust(_ item: DefaultWitnessPreference, value: Double) -> Double
    }

    final class FlaggedDefaultWitnessPreferenceAdjuster: DefaultWitnessPreferenceStep {
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

        func adjust(_ item: DefaultWitnessPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardDefaultWitnessPreferenceAdjuster: DefaultWitnessPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DefaultWitnessPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDefaultWitnessPreferenceAdjuster: DefaultWitnessPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultWitnessPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultWitnessPreferenceAdjuster: DefaultWitnessPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultWitnessPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default witness preference steps in order and keeps a trace of each.
    final class DefaultWitnessPreferenceEngine {
        var steps: [any DefaultWitnessPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultWitnessPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultWitnessPreference) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultWitnessPreferenceStep = steps[index]
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

        func evaluateAll(_ items: [DefaultWitnessPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultWitnessPreferenceEngine(_ flags: Kit.Flags.Registry) -> DefaultWitnessPreferenceEngine {
        return DefaultWitnessPreferenceEngine(
            steps: [
                FlaggedDefaultWitnessPreferenceAdjuster(
                    flags: flags,
                    flag: "default-witness-preference-batched",
                    percent: 9.3
                ),
                WardDefaultWitnessPreferenceAdjuster(factors: ["west": 0.75, "south": 1.26, "retail": 0.98]),
                TieredDefaultWitnessPreferenceAdjuster(
                    bounds: [2438.0, 4157.0, 6940.0, 8888.0],
                    rates: [1.02, 1.17, 1.13, 0.95]
                ),
                PercentDefaultWitnessPreferenceAdjuster(percent: 10.8),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 95592.2
        )
    }
}
