import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default cleaning preference calculation.
    protocol DefaultCleaningPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultCleaningPreference, value: Double) -> Double
    }

    final class TieredDefaultCleaningPreferenceAdjuster: DefaultCleaningPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCleaningPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DefaultCleaningPreferenceDurationMinutesOffsetAdjuster: DefaultCleaningPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: DefaultCleaningPreference, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class MinimumDefaultCleaningPreferenceAdjuster: DefaultCleaningPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCleaningPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default cleaning preference steps in order and keeps a trace of each.
    final class DefaultCleaningPreferenceEngine {
        var steps: [any DefaultCleaningPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCleaningPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultCleaningPreference) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCleaningPreferenceAdjuster = steps[index]
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

        func evaluateAll(_ items: [DefaultCleaningPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultCleaningPreferenceEngine() -> DefaultCleaningPreferenceEngine {
        return DefaultCleaningPreferenceEngine(
            steps: [
                TieredDefaultCleaningPreferenceAdjuster(bounds: [1355.0, 1663.0, 1749.0], rates: [0.82, 1.11, 1.15]),
                DefaultCleaningPreferenceDurationMinutesOffsetAdjuster(weight: 0.88),
                MinimumDefaultCleaningPreferenceAdjuster(minimum: 14.4),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 29541.8
        )
    }
}
