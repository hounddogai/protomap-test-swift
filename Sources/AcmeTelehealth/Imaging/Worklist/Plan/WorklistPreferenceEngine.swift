import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist preference calculation.
    protocol WorklistPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistPreference, value: Double) -> Double
    }

    final class RoundingWorklistPreferenceAdjuster: WorklistPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleWorklistPreferenceAdjuster: WorklistPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WorklistPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredWorklistPreferenceAdjuster: WorklistPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapWorklistPreferenceAdjuster: WorklistPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentWorklistPreferenceAdjuster: WorklistPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the worklist preference steps in order and keeps a trace of each.
    final class WorklistPreferenceEngine {
        var steps: [any WorklistPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistPreference) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [WorklistPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistPreferenceEngine() -> WorklistPreferenceEngine {
        return WorklistPreferenceEngine(
            steps: [
                RoundingWorklistPreferenceAdjuster(step: 5.0),
                TitleWorklistPreferenceAdjuster(factors: ["east": 1.01, "south": 0.84]),
                TieredWorklistPreferenceAdjuster(bounds: [1619.0, 3004.0, 6459.0], rates: [0.99, 0.87, 0.99]),
                CapWorklistPreferenceAdjuster(cap: 15420.0),
                PercentWorklistPreferenceAdjuster(percent: -17.5),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 30732.1
        )
    }
}
