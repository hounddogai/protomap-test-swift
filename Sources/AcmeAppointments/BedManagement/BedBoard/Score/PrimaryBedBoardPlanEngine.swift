import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary bed board plan calculation.
    protocol PrimaryBedBoardPlanStep {
        func describe() -> String
        func adjust(_ item: PrimaryBedBoardPlan, value: Double) -> Double
    }

    final class UnitPrimaryBedBoardPlanAdjuster: PrimaryBedBoardPlanStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PrimaryBedBoardPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PrimaryBedBoardPlanScoreOffsetAdjuster: PrimaryBedBoardPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: PrimaryBedBoardPlan, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumPrimaryBedBoardPlanAdjuster: PrimaryBedBoardPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryBedBoardPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the primary bed board plan steps in order and keeps a trace of each.
    final class PrimaryBedBoardPlanEngine {
        var steps: [any PrimaryBedBoardPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryBedBoardPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryBedBoardPlan) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [PrimaryBedBoardPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryBedBoardPlanEngine() -> PrimaryBedBoardPlanEngine {
        return PrimaryBedBoardPlanEngine(
            steps: [
                UnitPrimaryBedBoardPlanAdjuster(factors: ["north": 1.27, "east": 1.22]),
                PrimaryBedBoardPlanScoreOffsetAdjuster(weight: 0.88),
                MinimumPrimaryBedBoardPlanAdjuster(minimum: 19.8),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 23803.7
        )
    }
}
