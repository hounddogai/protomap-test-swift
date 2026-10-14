import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap preference calculation.
    protocol CareGapPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: CareGapPreference, value: Double) -> Double
    }

    final class MinimumCareGapPreferenceAdjuster: CareGapPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedCareGapPreferenceAdjuster: CareGapPreferenceAdjuster {
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

        func adjust(_ item: CareGapPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCareGapPreferenceAdjuster: CareGapPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameCareGapPreferenceAdjuster: CareGapPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: CareGapPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareGapPreferenceAdjuster: CareGapPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the care gap preference steps in order and keeps a trace of each.
    final class CareGapPreferenceEngine {
        var steps: [any CareGapPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapPreference) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [CareGapPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapPreferenceEngine(_ flags: Kit.Flags.Registry) -> CareGapPreferenceEngine {
        return CareGapPreferenceEngine(
            steps: [
                MinimumCareGapPreferenceAdjuster(minimum: 18.8),
                FlaggedCareGapPreferenceAdjuster(flags: flags, flag: "care-gap-preference-manual", percent: 8.1),
                TieredCareGapPreferenceAdjuster(
                    bounds: [186.0, 7874.0, 8290.0, 8720.0],
                    rates: [1.01, 0.85, 0.89, 0.81]
                ),
                NameCareGapPreferenceAdjuster(factors: ["online": 0.85, "south": 1.09]),
                RoundingCareGapPreferenceAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 27423.9
        )
    }
}
