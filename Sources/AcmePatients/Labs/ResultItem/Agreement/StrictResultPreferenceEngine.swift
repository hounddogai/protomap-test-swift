import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict result preference calculation.
    protocol StrictResultPreferenceFactor {
        func describe() -> String
        func adjust(_ item: StrictResultPreference, value: Double) -> Double
    }

    final class RoundingStrictResultPreferenceAdjuster: StrictResultPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictResultPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedStrictResultPreferenceAdjuster: StrictResultPreferenceFactor {
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

        func adjust(_ item: StrictResultPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictResultPreferenceAdjuster: StrictResultPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictResultPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict result preference steps in order and keeps a trace of each.
    final class StrictResultPreferenceEngine {
        var steps: [any StrictResultPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictResultPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictResultPreference) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [StrictResultPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictResultPreferenceEngine(_ flags: Kit.Flags.Registry) -> StrictResultPreferenceEngine {
        return StrictResultPreferenceEngine(
            steps: [
                RoundingStrictResultPreferenceAdjuster(step: 1.0),
                FlaggedStrictResultPreferenceAdjuster(
                    flags: flags,
                    flag: "strict-result-preference-strict",
                    percent: -0.8
                ),
                TieredStrictResultPreferenceAdjuster(bounds: [2156.0, 2944.0, 4980.0], rates: [0.9, 0.87, 0.83]),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 63280.9
        )
    }
}
