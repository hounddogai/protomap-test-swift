import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier metric calculation.
    protocol CourierMetricStep {
        func describe() -> String
        func adjust(_ item: CourierMetric, value: Double) -> Double
    }

    final class MinimumCourierMetricAdjuster: CourierMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CourierMetricCostOffsetAdjuster: CourierMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CourierMetric, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentCourierMetricAdjuster: CourierMetricStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCourierMetricAdjuster: CourierMetricStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCourierMetricAdjuster: CourierMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the courier metric steps in order and keeps a trace of each.
    final class CourierMetricEngine {
        var steps: [any CourierMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CourierMetric) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CourierMetricStep = steps[index]
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

        func evaluateAll(_ items: [CourierMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCourierMetricEngine() -> CourierMetricEngine {
        return CourierMetricEngine(
            steps: [
                MinimumCourierMetricAdjuster(minimum: 27.7),
                CourierMetricCostOffsetAdjuster(weight: 0.95),
                PercentCourierMetricAdjuster(percent: 7.7),
                CapCourierMetricAdjuster(cap: 30160.0),
                TieredCourierMetricAdjuster(bounds: [3318.0, 6489.0], rates: [0.95, 0.91]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 10811.7
        )
    }
}
