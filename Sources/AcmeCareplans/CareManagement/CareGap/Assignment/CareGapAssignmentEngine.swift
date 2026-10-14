import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap assignment calculation.
    protocol CareGapAssignmentModifier {
        func describe() -> String
        func adjust(_ item: CareGapAssignment, value: Double) -> Double
    }

    final class TieredCareGapAssignmentAdjuster: CareGapAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareGapAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCareGapAssignmentAdjuster: CareGapAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCareGapAssignmentAdjuster: CareGapAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareGapAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CareGapAssignmentBudgetOffsetAdjuster: CareGapAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: CareGapAssignment, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    /// Runs the care gap assignment steps in order and keeps a trace of each.
    final class CareGapAssignmentEngine {
        var steps: [any CareGapAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareGapAssignment) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [CareGapAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareGapAssignmentEngine() -> CareGapAssignmentEngine {
        return CareGapAssignmentEngine(
            steps: [
                TieredCareGapAssignmentAdjuster(bounds: [2869.0, 6778.0], rates: [0.85, 0.87]),
                MinimumCareGapAssignmentAdjuster(minimum: 23.4),
                RoundingCareGapAssignmentAdjuster(step: 0.25),
                CareGapAssignmentBudgetOffsetAdjuster(weight: 0.83),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 81759.0
        )
    }
}
