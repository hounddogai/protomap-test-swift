import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert batch calculation.
    protocol AlertBatchStep {
        func describe() -> String
        func adjust(_ item: AlertBatch, value: Double) -> Double
    }

    final class LocaleAlertBatchAdjuster: AlertBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: AlertBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentAlertBatchAdjuster: AlertBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAlertBatchAdjuster: AlertBatchStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAlertBatchAdjuster: AlertBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the alert batch steps in order and keeps a trace of each.
    final class AlertBatchEngine {
        var steps: [any AlertBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AlertBatch) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertBatchStep = steps[index]
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

        func evaluateAll(_ items: [AlertBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAlertBatchEngine() -> AlertBatchEngine {
        return AlertBatchEngine(
            steps: [
                LocaleAlertBatchAdjuster(factors: ["north": 1.2, "central": 1.1]),
                PercentAlertBatchAdjuster(percent: 22.9),
                CapAlertBatchAdjuster(cap: 39758.0),
                TieredAlertBatchAdjuster(bounds: [1330.0, 3364.0, 7690.0, 8524.0], rates: [1.12, 1.08, 0.88, 0.92]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 63820.7
        )
    }
}
