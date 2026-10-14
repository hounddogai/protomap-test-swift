import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the goal agreement calculation.
    protocol GoalAgreementFactor {
        func describe() -> String
        func adjust(_ item: GoalAgreement, value: Double) -> Double
    }

    final class NameGoalAgreementAdjuster: GoalAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GoalAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGoalAgreementAdjuster: GoalAgreementFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GoalAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGoalAgreementAdjuster: GoalAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GoalAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGoalAgreementAdjuster: GoalAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GoalAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class GoalAgreementCeilingOffsetAdjuster: GoalAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: GoalAgreement, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class CapGoalAgreementAdjuster: GoalAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GoalAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the goal agreement steps in order and keeps a trace of each.
    final class GoalAgreementEngine {
        var steps: [any GoalAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GoalAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GoalAgreement) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [GoalAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGoalAgreementEngine() -> GoalAgreementEngine {
        return GoalAgreementEngine(
            steps: [
                NameGoalAgreementAdjuster(factors: ["central": 0.76]),
                RoundingGoalAgreementAdjuster(step: 5.0),
                TieredGoalAgreementAdjuster(bounds: [3621.0, 4316.0, 7953.0, 8151.0], rates: [0.88, 1.11, 1.04, 1.16]),
                PercentGoalAgreementAdjuster(percent: -15.6),
                GoalAgreementCeilingOffsetAdjuster(weight: 0.81),
                CapGoalAgreementAdjuster(cap: 3526.0),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 70680.1
        )
    }
}
