import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the credential budget calculation.
    protocol CredentialBudgetModifier {
        func describe() -> String
        func adjust(_ item: CredentialBudget, value: Double) -> Double
    }

    final class MinimumCredentialBudgetAdjuster: CredentialBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CredentialBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCredentialBudgetAdjuster: CredentialBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CredentialBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CredentialBudgetCeilingOffsetAdjuster: CredentialBudgetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: CredentialBudget, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the credential budget steps in order and keeps a trace of each.
    final class CredentialBudgetEngine {
        var steps: [any CredentialBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CredentialBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CredentialBudget) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CredentialBudgetModifier = steps[index]
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

        func evaluateAll(_ items: [CredentialBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCredentialBudgetEngine() -> CredentialBudgetEngine {
        return CredentialBudgetEngine(
            steps: [
                MinimumCredentialBudgetAdjuster(minimum: 29.9),
                PercentCredentialBudgetAdjuster(percent: 11.3),
                CredentialBudgetCeilingOffsetAdjuster(weight: 1.59),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 84236.9
        )
    }
}
