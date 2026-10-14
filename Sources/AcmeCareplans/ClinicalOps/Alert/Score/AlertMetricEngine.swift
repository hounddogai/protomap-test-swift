import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert metric calculation.
    protocol AlertMetricFactor {
        func describe() -> String
        func adjust(_ item: AlertMetric, value: Double) -> Double
    }

    final class MinimumAlertMetricAdjuster: AlertMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAlertMetricAdjuster: AlertMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAlertMetricAdjuster: AlertMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentAlertMetricAdjuster: AlertMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AlertMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the alert metric steps in order and keeps a trace of each.
    final class AlertMetricEngine {
        var steps: [any AlertMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertMetric) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertMetricFactor = steps[index]
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

        func evaluateAll(_ items: [AlertMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertMetricEngine() -> AlertMetricEngine {
        return AlertMetricEngine(
            steps: [
                MinimumAlertMetricAdjuster(minimum: 16.2),
                CapAlertMetricAdjuster(cap: 46253.0),
                TieredAlertMetricAdjuster(bounds: [2094.0, 6334.0], rates: [0.83, 1.0]),
                SegmentAlertMetricAdjuster(factors: ["north": 1.0, "south": 1.27, "central": 1.35]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 43331.8
        )
    }
}
