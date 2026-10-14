import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling statement preference calculation.
    protocol RollingStatementPreferenceStep {
        func describe() -> String
        func adjust(_ item: RollingStatementPreference, value: Double) -> Double
    }

    final class RoundingRollingStatementPreferenceAdjuster: RollingStatementPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingStatementPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingStatementPreferenceAdjuster: RollingStatementPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingStatementPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelRollingStatementPreferenceAdjuster: RollingStatementPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingStatementPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling statement preference steps in order and keeps a trace of each.
    final class RollingStatementPreferenceEngine {
        var steps: [any RollingStatementPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingStatementPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingStatementPreference) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [RollingStatementPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingStatementPreferenceEngine() -> RollingStatementPreferenceEngine {
        return RollingStatementPreferenceEngine(
            steps: [
                RoundingRollingStatementPreferenceAdjuster(step: 0.25),
                CapRollingStatementPreferenceAdjuster(cap: 45728.0),
                LabelRollingStatementPreferenceAdjuster(factors: ["west": 0.93]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 9312.6
        )
    }
}
