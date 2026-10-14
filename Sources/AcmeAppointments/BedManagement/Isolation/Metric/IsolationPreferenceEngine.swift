import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation preference calculation.
    protocol IsolationPreferenceFactor {
        func describe() -> String
        func adjust(_ item: IsolationPreference, value: Double) -> Double
    }

    final class TieredIsolationPreferenceAdjuster: IsolationPreferenceFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingIsolationPreferenceAdjuster: IsolationPreferenceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: IsolationPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class IsolationPreferenceRateOffsetAdjuster: IsolationPreferenceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: IsolationPreference, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumIsolationPreferenceAdjuster: IsolationPreferenceFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the isolation preference steps in order and keeps a trace of each.
    final class IsolationPreferenceEngine {
        var steps: [any IsolationPreferenceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationPreferenceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: IsolationPreference) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationPreferenceFactor = steps[index]
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

        func evaluateAll(_ items: [IsolationPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultIsolationPreferenceEngine() -> IsolationPreferenceEngine {
        return IsolationPreferenceEngine(
            steps: [
                TieredIsolationPreferenceAdjuster(
                    bounds: [2825.0, 4566.0, 7308.0, 9091.0],
                    rates: [1.04, 0.95, 1.02, 1.03]
                ),
                RoundingIsolationPreferenceAdjuster(step: 0.1),
                IsolationPreferenceRateOffsetAdjuster(weight: 1.41),
                MinimumIsolationPreferenceAdjuster(minimum: 40.6),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 85637.7
        )
    }
}
