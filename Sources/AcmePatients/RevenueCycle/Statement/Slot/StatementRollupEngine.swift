import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement rollup calculation.
    protocol StatementRollupModifier {
        func describe() -> String
        func adjust(_ item: StatementRollup, value: Double) -> Double
    }

    final class RoundingStatementRollupAdjuster: StatementRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StatementRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStatementRollupAdjuster: StatementRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitStatementRollupAdjuster: StatementRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StatementRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredStatementRollupAdjuster: StatementRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStatementRollupAdjuster: StatementRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement rollup steps in order and keeps a trace of each.
    final class StatementRollupEngine {
        var steps: [any StatementRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StatementRollup) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [StatementRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStatementRollupEngine() -> StatementRollupEngine {
        return StatementRollupEngine(
            steps: [
                RoundingStatementRollupAdjuster(step: 0.25),
                MinimumStatementRollupAdjuster(minimum: 17.9),
                UnitStatementRollupAdjuster(factors: ["west": 1.34, "online": 1.09]),
                TieredStatementRollupAdjuster(bounds: [366.0, 4816.0, 9564.0], rates: [0.96, 0.88, 1.12]),
                PercentStatementRollupAdjuster(percent: -17.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 82627.9
        )
    }
}
