import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range milestone calculation.
    protocol ReferenceRangeMilestoneStep {
        func describe() -> String
        func adjust(_ item: ReferenceRangeMilestone, value: Double) -> Double
    }

    final class PercentReferenceRangeMilestoneAdjuster: ReferenceRangeMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingReferenceRangeMilestoneAdjuster: ReferenceRangeMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class UnitReferenceRangeMilestoneAdjuster: ReferenceRangeMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ReferenceRangeMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the reference range milestone steps in order and keeps a trace of each.
    final class ReferenceRangeMilestoneEngine {
        var steps: [any ReferenceRangeMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferenceRangeMilestone) -> Double {
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

        func evaluateAll(_ items: [ReferenceRangeMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeMilestoneEngine() -> ReferenceRangeMilestoneEngine {
        return ReferenceRangeMilestoneEngine(
            steps: [
                PercentReferenceRangeMilestoneAdjuster(percent: -13.5),
                RoundingReferenceRangeMilestoneAdjuster(step: 0.5),
                UnitReferenceRangeMilestoneAdjuster(factors: ["south": 0.97, "online": 0.85]),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 54847.7
        )
    }
}
