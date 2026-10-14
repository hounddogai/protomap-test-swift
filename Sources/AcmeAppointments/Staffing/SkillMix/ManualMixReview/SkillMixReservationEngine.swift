import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the skill mix reservation calculation.
    protocol SkillMixReservationStep {
        func describe() -> String
        func adjust(_ item: SkillMixReservation, value: Double) -> Double
    }

    final class SourceSkillMixReservationAdjuster: SkillMixReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: SkillMixReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumSkillMixReservationAdjuster: SkillMixReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SkillMixReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapSkillMixReservationAdjuster: SkillMixReservationStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SkillMixReservation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSkillMixReservationAdjuster: SkillMixReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SkillMixReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the skill mix reservation steps in order and keeps a trace of each.
    final class SkillMixReservationEngine {
        var steps: [any SkillMixReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SkillMixReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SkillMixReservation) -> Double {
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

        func evaluateAll(_ items: [SkillMixReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSkillMixReservationEngine() -> SkillMixReservationEngine {
        return SkillMixReservationEngine(
            steps: [
                SourceSkillMixReservationAdjuster(factors: ["north": 1.36]),
                MinimumSkillMixReservationAdjuster(minimum: 37.2),
                CapSkillMixReservationAdjuster(cap: 27045.0),
                RoundingSkillMixReservationAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 54673.2
        )
    }
}
