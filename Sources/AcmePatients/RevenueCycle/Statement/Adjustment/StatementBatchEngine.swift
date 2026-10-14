import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement batch calculation.
    protocol StatementBatchFactor {
        func describe() -> String
        func adjust(_ item: StatementBatch, value: Double) -> Double
    }

    final class WardStatementBatchAdjuster: StatementBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: StatementBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStatementBatchAdjuster: StatementBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStatementBatchAdjuster: StatementBatchFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStatementBatchAdjuster: StatementBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStatementBatchAdjuster: StatementBatchFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the statement batch steps in order and keeps a trace of each.
    final class StatementBatchEngine {
        var steps: [any StatementBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StatementBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementBatchFactor = steps[index]
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

        func evaluateAll(_ items: [StatementBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStatementBatchEngine() -> StatementBatchEngine {
        return StatementBatchEngine(
            steps: [
                WardStatementBatchAdjuster(factors: ["west": 1.07, "north": 1.21]),
                CapStatementBatchAdjuster(cap: 41492.0),
                PercentStatementBatchAdjuster(percent: 0.2),
                TieredStatementBatchAdjuster(bounds: [4022.0, 7178.0], rates: [1.05, 0.97]),
                RoundingStatementBatchAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 33175.8
        )
    }
}
