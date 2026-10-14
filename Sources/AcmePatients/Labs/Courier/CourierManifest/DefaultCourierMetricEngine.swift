import AcmePlatform
import Foundation

extension Labs {
    /// One step of the default courier metric calculation.
    protocol DefaultCourierMetricStep {
        func describe() -> String
        func adjust(_ item: DefaultCourierMetric, value: Double) -> Double
    }

    final class DefaultCourierMetricFloorValueOffsetAdjuster: DefaultCourierMetricStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: DefaultCourierMetric, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class MinimumDefaultCourierMetricAdjuster: DefaultCourierMetricStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultCourierMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredDefaultCourierMetricAdjuster: DefaultCourierMetricStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultCourierMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default courier metric steps in order and keeps a trace of each.
    final class DefaultCourierMetricEngine {
        var steps: [any DefaultCourierMetricStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultCourierMetricStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultCourierMetric) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultCourierMetricStep = steps[index]
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

        func evaluateAll(_ items: [DefaultCourierMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultCourierMetricEngine() -> DefaultCourierMetricEngine {
        return DefaultCourierMetricEngine(
            steps: [
                DefaultCourierMetricFloorValueOffsetAdjuster(weight: 1.56),
                MinimumDefaultCourierMetricAdjuster(minimum: 49.9),
                TieredDefaultCourierMetricAdjuster(bounds: [5215.0, 8934.0], rates: [0.91, 1.12]),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 64126.9
        )
    }
}
