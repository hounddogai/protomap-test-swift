import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling worklist preference calculation.
    protocol RollingWorklistPreferenceFactor {
        func describe() -> String
        func adjust(_ item: RollingWorklistPreference, value: Double) -> Double
    }

    final class TieredRollingWorklistPreferenceAdjuster: RollingWorklistPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingWorklistPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapRollingWorklistPreferenceAdjuster: RollingWorklistPreferenceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingWorklistPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameRollingWorklistPreferenceAdjuster: RollingWorklistPreferenceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingWorklistPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling worklist preference steps in order and keeps a trace of each.
    final class RollingWorklistPreferenceEngine {
        var steps: [any RollingWorklistPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingWorklistPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RollingWorklistPreference) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingWorklistPreferenceFactor = steps[index]
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

        func evaluateAll(_ items: [RollingWorklistPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRollingWorklistPreferenceEngine() -> RollingWorklistPreferenceEngine {
        return RollingWorklistPreferenceEngine(
            steps: [
                TieredRollingWorklistPreferenceAdjuster(bounds: [959.0, 5111.0, 9299.0], rates: [1.12, 1.07, 0.84]),
                CapRollingWorklistPreferenceAdjuster(cap: 9630.0),
                NameRollingWorklistPreferenceAdjuster(factors: ["online": 0.72, "retail": 0.83, "north": 1.34]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 69677.4
        )
    }
}
