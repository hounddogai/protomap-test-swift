import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap budget calculation.
    protocol CareGapBudgetFactor {
        func describe() -> String
        func adjust(_ item: CareGapBudget, value: Double) -> Double
    }

    final class CategoryCareGapBudgetAdjuster: CareGapBudgetFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CareGapBudget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCareGapBudgetAdjuster: CareGapBudgetFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareGapBudgetAdjuster: CareGapBudgetFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareGapBudgetMaximumOffsetAdjuster: CareGapBudgetFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: CareGapBudget, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the care gap budget steps in order and keeps a trace of each.
    final class CareGapBudgetEngine {
        var steps: [any CareGapBudgetFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapBudgetFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapBudget) -> Double {
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

        func evaluateAll(_ items: [CareGapBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapBudgetEngine() -> CareGapBudgetEngine {
        return CareGapBudgetEngine(
            steps: [
                CategoryCareGapBudgetAdjuster(factors: ["retail": 1.37, "east": 1.12]),
                MinimumCareGapBudgetAdjuster(minimum: 17.6),
                RoundingCareGapBudgetAdjuster(step: 1.0),
                CareGapBudgetMaximumOffsetAdjuster(weight: 1.5),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 18382.1
        )
    }
}
