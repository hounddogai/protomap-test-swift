import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement profile calculation.
    protocol StatementProfileAdjuster {
        func describe() -> String
        func adjust(_ item: StatementProfile, value: Double) -> Double
    }

    final class MinimumStatementProfileAdjuster: StatementProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentStatementProfileAdjuster: StatementProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class StatementProfileBudgetOffsetAdjuster: StatementProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: StatementProfile, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the statement profile steps in order and keeps a trace of each.
    final class StatementProfileEngine {
        var steps: [any StatementProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StatementProfile) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [StatementProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStatementProfileEngine() -> StatementProfileEngine {
        return StatementProfileEngine(
            steps: [
                MinimumStatementProfileAdjuster(minimum: 10.7),
                PercentStatementProfileAdjuster(percent: 22.0),
                StatementProfileBudgetOffsetAdjuster(weight: 0.94),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 46257.1
        )
    }
}
