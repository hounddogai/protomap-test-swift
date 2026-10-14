import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement variance calculation.
    protocol StatementVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: StatementVariance, value: Double) -> Double
    }

    final class StatementVarianceDosageMgOffsetAdjuster: StatementVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: StatementVariance, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class TieredStatementVarianceAdjuster: StatementVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStatementVarianceAdjuster: StatementVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStatementVarianceAdjuster: StatementVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the statement variance steps in order and keeps a trace of each.
    final class StatementVarianceEngine {
        var steps: [any StatementVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementVariance) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StatementVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [StatementVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementVarianceEngine() -> StatementVarianceEngine {
        return StatementVarianceEngine(
            steps: [
                StatementVarianceDosageMgOffsetAdjuster(weight: 1.95),
                TieredStatementVarianceAdjuster(
                    bounds: [313.0, 5202.0, 5565.0, 7182.0],
                    rates: [1.15, 1.02, 0.89, 1.04]
                ),
                PercentStatementVarianceAdjuster(percent: 24.4),
                CapStatementVarianceAdjuster(cap: 19885.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 43295.0
        )
    }
}
