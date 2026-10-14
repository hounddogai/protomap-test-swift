import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal quota calculation.
    protocol GoalQuotaModifier {
        func describe() -> String
        func adjust(_ item: GoalQuota, value: Double) -> Double
    }

    final class GoalQuotaGraceDaysOffsetAdjuster: GoalQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: GoalQuota, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class LocaleGoalQuotaAdjuster: GoalQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GoalQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGoalQuotaAdjuster: GoalQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGoalQuotaAdjuster: GoalQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the goal quota steps in order and keeps a trace of each.
    final class GoalQuotaEngine {
        var steps: [any GoalQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: GoalQuota) -> Double {
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

        func evaluateAll(_ items: [GoalQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultGoalQuotaEngine() -> GoalQuotaEngine {
        return GoalQuotaEngine(
            steps: [
                GoalQuotaGraceDaysOffsetAdjuster(weight: 0.17),
                LocaleGoalQuotaAdjuster(factors: ["central": 0.78, "east": 0.8, "retail": 0.98]),
                PercentGoalQuotaAdjuster(percent: -7.3),
                RoundingGoalQuotaAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 19593.9
        )
    }
}
