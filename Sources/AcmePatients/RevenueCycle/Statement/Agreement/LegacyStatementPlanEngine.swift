import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy statement plan calculation.
    protocol LegacyStatementPlanFactor {
        func describe() -> String
        func adjust(_ item: LegacyStatementPlan, value: Double) -> Double
    }

    final class PercentLegacyStatementPlanAdjuster: LegacyStatementPlanFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyStatementPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacyStatementPlanAdjuster: LegacyStatementPlanFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyStatementPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelLegacyStatementPlanAdjuster: LegacyStatementPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyStatementPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLegacyStatementPlanAdjuster: LegacyStatementPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyStatementPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy statement plan steps in order and keeps a trace of each.
    final class LegacyStatementPlanEngine {
        var steps: [any LegacyStatementPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyStatementPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyStatementPlan) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyStatementPlanFactor = steps[index]
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

        func evaluateAll(_ items: [LegacyStatementPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyStatementPlanEngine() -> LegacyStatementPlanEngine {
        return LegacyStatementPlanEngine(
            steps: [
                PercentLegacyStatementPlanAdjuster(percent: 17.1),
                CapLegacyStatementPlanAdjuster(cap: 36789.0),
                LabelLegacyStatementPlanAdjuster(factors: ["online": 1.31, "retail": 1.05, "south": 1.31]),
                RoundingLegacyStatementPlanAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 16031.1
        )
    }
}
