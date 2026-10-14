import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the weighted acuity plan budget calculation.
    protocol WeightedAcuityPlanBudgetModifier {
        func describe() -> String
        func adjust(_ item: WeightedAcuityPlanBudget, value: Double) -> Double
    }

    final class PercentWeightedAcuityPlanBudgetAdjuster: WeightedAcuityPlanBudgetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedAcuityPlanBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumWeightedAcuityPlanBudgetAdjuster: WeightedAcuityPlanBudgetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedAcuityPlanBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentWeightedAcuityPlanBudgetAdjuster: WeightedAcuityPlanBudgetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: WeightedAcuityPlanBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWeightedAcuityPlanBudgetAdjuster: WeightedAcuityPlanBudgetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedAcuityPlanBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the weighted acuity plan budget steps in order and keeps a trace of each.
    final class WeightedAcuityPlanBudgetEngine {
        var steps: [any WeightedAcuityPlanBudgetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedAcuityPlanBudgetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedAcuityPlanBudget) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [WeightedAcuityPlanBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedAcuityPlanBudgetEngine() -> WeightedAcuityPlanBudgetEngine {
        return WeightedAcuityPlanBudgetEngine(
            steps: [
                PercentWeightedAcuityPlanBudgetAdjuster(percent: -18.3),
                MinimumWeightedAcuityPlanBudgetAdjuster(minimum: 27.7),
                SegmentWeightedAcuityPlanBudgetAdjuster(factors: ["east": 1.1, "west": 0.92, "central": 1.35]),
                CapWeightedAcuityPlanBudgetAdjuster(cap: 40514.0),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 87528.8
        )
    }
}
