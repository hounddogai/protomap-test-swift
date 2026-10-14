import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped bed board budget calculation.
    protocol CappedBedBoardBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: CappedBedBoardBudget, value: Double) -> Double
    }

    final class LabelCappedBedBoardBudgetAdjuster: CappedBedBoardBudgetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedBedBoardBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCappedBedBoardBudgetAdjuster: CappedBedBoardBudgetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedBedBoardBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedBedBoardBudgetAdjuster: CappedBedBoardBudgetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedBedBoardBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped bed board budget steps in order and keeps a trace of each.
    final class CappedBedBoardBudgetEngine {
        var steps: [any CappedBedBoardBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedBedBoardBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedBedBoardBudget) -> Double {
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

        func evaluateAll(_ items: [CappedBedBoardBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedBedBoardBudgetEngine() -> CappedBedBoardBudgetEngine {
        return CappedBedBoardBudgetEngine(
            steps: [
                LabelCappedBedBoardBudgetAdjuster(factors: ["north": 1.25, "online": 1.26]),
                PercentCappedBedBoardBudgetAdjuster(percent: 21.6),
                MinimumCappedBedBoardBudgetAdjuster(minimum: 13.9),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 5412.5
        )
    }
}
