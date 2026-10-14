import AcmePlatform
import Foundation

extension Labs {
    /// One step of the specimen milestone calculation.
    protocol SpecimenMilestoneModifier {
        func describe() -> String
        func adjust(_ item: SpecimenMilestone, value: Double) -> Double
    }

    final class CapSpecimenMilestoneAdjuster: SpecimenMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SpecimenMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSpecimenMilestoneAdjuster: SpecimenMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SpecimenMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FacilitySpecimenMilestoneAdjuster: SpecimenMilestoneModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SpecimenMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the specimen milestone steps in order and keeps a trace of each.
    final class SpecimenMilestoneEngine {
        var steps: [any SpecimenMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SpecimenMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: SpecimenMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any SpecimenMilestoneModifier = steps[index]
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

        func evaluateAll(_ items: [SpecimenMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultSpecimenMilestoneEngine() -> SpecimenMilestoneEngine {
        return SpecimenMilestoneEngine(
            steps: [
                CapSpecimenMilestoneAdjuster(cap: 7693.0),
                RoundingSpecimenMilestoneAdjuster(step: 5.0),
                FacilitySpecimenMilestoneAdjuster(factors: ["online": 1.18, "central": 0.71]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 7850.2
        )
    }
}
