import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement preference calculation.
    protocol StatementPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: StatementPreference, value: Double) -> Double
    }

    final class NameStatementPreferenceAdjuster: StatementPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StatementPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStatementPreferenceAdjuster: StatementPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StatementPreferenceRefillsOffsetAdjuster: StatementPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: StatementPreference, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the statement preference steps in order and keeps a trace of each.
    final class StatementPreferenceEngine {
        var steps: [any StatementPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StatementPreference) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [StatementPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStatementPreferenceEngine() -> StatementPreferenceEngine {
        return StatementPreferenceEngine(
            steps: [
                NameStatementPreferenceAdjuster(factors: ["west": 0.96, "south": 0.82]),
                CapStatementPreferenceAdjuster(cap: 19445.0),
                StatementPreferenceRefillsOffsetAdjuster(weight: 0.95),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 5765.2
        )
    }
}
