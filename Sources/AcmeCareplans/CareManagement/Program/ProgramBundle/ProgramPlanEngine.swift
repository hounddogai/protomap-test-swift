import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the program plan calculation.
    protocol ProgramPlanFactor {
        func describe() -> String
        func adjust(_ item: ProgramPlan, value: Double) -> Double
    }

    final class RoundingProgramPlanAdjuster: ProgramPlanFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProgramPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class ProgramPlanGraceDaysOffsetAdjuster: ProgramPlanFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: ProgramPlan, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredProgramPlanAdjuster: ProgramPlanFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProgramPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitProgramPlanAdjuster: ProgramPlanFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ProgramPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the program plan steps in order and keeps a trace of each.
    final class ProgramPlanEngine {
        var steps: [any ProgramPlanFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProgramPlanFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProgramPlan) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [ProgramPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProgramPlanEngine() -> ProgramPlanEngine {
        return ProgramPlanEngine(
            steps: [
                RoundingProgramPlanAdjuster(step: 0.05),
                ProgramPlanGraceDaysOffsetAdjuster(weight: 1.47),
                TieredProgramPlanAdjuster(bounds: [1990.0, 5978.0, 7938.0], rates: [1.19, 0.97, 1.05]),
                UnitProgramPlanAdjuster(factors: ["south": 1.07, "north": 0.97]),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 50624.6
        )
    }
}
