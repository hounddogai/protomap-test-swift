import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation metric calculation.
    protocol IsolationMetricAdjuster {
        func describe() -> String
        func adjust(_ item: IsolationMetric, value: Double) -> Double
    }

    final class MinimumIsolationMetricAdjuster: IsolationMetricAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredIsolationMetricAdjuster: IsolationMetricAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapIsolationMetricAdjuster: IsolationMetricAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: IsolationMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the isolation metric steps in order and keeps a trace of each.
    final class IsolationMetricEngine {
        var steps: [any IsolationMetricAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationMetricAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: IsolationMetric) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationMetricAdjuster = steps[index]
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

        func evaluateAll(_ items: [IsolationMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultIsolationMetricEngine() -> IsolationMetricEngine {
        return IsolationMetricEngine(
            steps: [
                MinimumIsolationMetricAdjuster(minimum: 14.2),
                TieredIsolationMetricAdjuster(bounds: [1630.0, 8815.0], rates: [0.81, 1.19]),
                CapIsolationMetricAdjuster(cap: 44645.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 48674.2
        )
    }
}
