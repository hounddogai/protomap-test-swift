import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization plan calculation.
    protocol AuthorizationPlanFactor {
        func describe() -> String
        func adjust(_ item: AuthorizationPlan, value: Double) -> Double
    }

    final class RoundingAuthorizationPlanAdjuster: AuthorizationPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AuthorizationPlanCopayOffsetAdjuster: AuthorizationPlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: AuthorizationPlan, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CategoryAuthorizationPlanAdjuster: AuthorizationPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AuthorizationPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the authorization plan steps in order and keeps a trace of each.
    final class AuthorizationPlanEngine {
        var steps: [any AuthorizationPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationPlan) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationPlanFactor = steps[index]
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

        func evaluateAll(_ items: [AuthorizationPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationPlanEngine() -> AuthorizationPlanEngine {
        return AuthorizationPlanEngine(
            steps: [
                RoundingAuthorizationPlanAdjuster(step: 0.5),
                AuthorizationPlanCopayOffsetAdjuster(weight: 0.02),
                CategoryAuthorizationPlanAdjuster(factors: ["south": 1.33]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 23892.2
        )
    }
}
