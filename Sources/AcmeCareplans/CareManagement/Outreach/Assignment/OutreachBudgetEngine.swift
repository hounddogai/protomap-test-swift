import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the outreach budget calculation.
    protocol OutreachBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: OutreachBudget, value: Double) -> Double
    }

    final class LocaleOutreachBudgetAdjuster: OutreachBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: OutreachBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumOutreachBudgetAdjuster: OutreachBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OutreachBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingOutreachBudgetAdjuster: OutreachBudgetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OutreachBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the outreach budget steps in order and keeps a trace of each.
    final class OutreachBudgetEngine {
        var steps: [any OutreachBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OutreachBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OutreachBudget) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any OutreachBudgetAdjuster = steps[index]
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

        func evaluateAll(_ items: [OutreachBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOutreachBudgetEngine() -> OutreachBudgetEngine {
        return OutreachBudgetEngine(
            steps: [
                LocaleOutreachBudgetAdjuster(factors: ["online": 1.29, "south": 1.18, "east": 1.19]),
                MinimumOutreachBudgetAdjuster(minimum: 36.3),
                RoundingOutreachBudgetAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 89961.1
        )
    }
}
