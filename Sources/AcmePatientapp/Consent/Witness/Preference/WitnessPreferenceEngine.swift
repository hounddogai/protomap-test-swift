import AcmePlatform
import Foundation

extension Consent {
    /// One step of the witness preference calculation.
    protocol WitnessPreferenceModifier {
        func describe() -> String
        func adjust(_ item: WitnessPreference, value: Double) -> Double
    }

    final class MinimumWitnessPreferenceAdjuster: WitnessPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WitnessPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredWitnessPreferenceAdjuster: WitnessPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WitnessPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWitnessPreferenceAdjuster: WitnessPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WitnessPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWitnessPreferenceAdjuster: WitnessPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WitnessPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedWitnessPreferenceAdjuster: WitnessPreferenceModifier {
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

        func adjust(_ item: WitnessPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the witness preference steps in order and keeps a trace of each.
    final class WitnessPreferenceEngine {
        var steps: [any WitnessPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WitnessPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WitnessPreference) -> Double {
            var current = item.weightedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WitnessPreferenceModifier = steps[index]
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

        func evaluateAll(_ items: [WitnessPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWitnessPreferenceEngine(_ flags: Kit.Flags.Registry) -> WitnessPreferenceEngine {
        return WitnessPreferenceEngine(
            steps: [
                MinimumWitnessPreferenceAdjuster(minimum: 31.6),
                TieredWitnessPreferenceAdjuster(bounds: [758.0, 2674.0], rates: [1.06, 0.86]),
                PercentWitnessPreferenceAdjuster(percent: -0.5),
                RoundingWitnessPreferenceAdjuster(step: 0.05),
                FlaggedWitnessPreferenceAdjuster(flags: flags, flag: "witness-preference-legacy", percent: 2.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 16683.8
        )
    }
}
