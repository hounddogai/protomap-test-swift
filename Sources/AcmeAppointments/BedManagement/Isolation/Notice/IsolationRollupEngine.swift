import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the isolation rollup calculation.
    protocol IsolationRollupStep {
        func describe() -> String
        func adjust(_ item: IsolationRollup, value: Double) -> Double
    }

    final class MinimumIsolationRollupAdjuster: IsolationRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: IsolationRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class IsolationRollupBudgetOffsetAdjuster: IsolationRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: IsolationRollup, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class TieredIsolationRollupAdjuster: IsolationRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: IsolationRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the isolation rollup steps in order and keeps a trace of each.
    final class IsolationRollupEngine {
        var steps: [any IsolationRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any IsolationRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: IsolationRollup) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any IsolationRollupStep = steps[index]
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

        func evaluateAll(_ items: [IsolationRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultIsolationRollupEngine() -> IsolationRollupEngine {
        return IsolationRollupEngine(
            steps: [
                MinimumIsolationRollupAdjuster(minimum: 12.3),
                IsolationRollupBudgetOffsetAdjuster(weight: 1.02),
                TieredIsolationRollupAdjuster(
                    bounds: [720.0, 3926.0, 4734.0, 9926.0],
                    rates: [1.05, 1.14, 1.19, 1.19]
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 24905.3
        )
    }
}
