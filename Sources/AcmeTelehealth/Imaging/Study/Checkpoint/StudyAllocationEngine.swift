import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study allocation calculation.
    protocol StudyAllocationModifier {
        func describe() -> String
        func adjust(_ item: StudyAllocation, value: Double) -> Double
    }

    final class RoundingStudyAllocationAdjuster: StudyAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentStudyAllocationAdjuster: StudyAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumStudyAllocationAdjuster: StudyAllocationModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyAllocation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleStudyAllocationAdjuster: StudyAllocationModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StudyAllocation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStudyAllocationAdjuster: StudyAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StudyAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StudyAllocationCostOffsetAdjuster: StudyAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: StudyAllocation, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    /// Runs the study allocation steps in order and keeps a trace of each.
    final class StudyAllocationEngine {
        var steps: [any StudyAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StudyAllocation) -> Double {
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

        func evaluateAll(_ items: [StudyAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStudyAllocationEngine() -> StudyAllocationEngine {
        return StudyAllocationEngine(
            steps: [
                RoundingStudyAllocationAdjuster(step: 1.0),
                PercentStudyAllocationAdjuster(percent: 10.8),
                MinimumStudyAllocationAdjuster(minimum: 11.3),
                LocaleStudyAllocationAdjuster(factors: ["east": 1.03, "online": 0.89]),
                CapStudyAllocationAdjuster(cap: 16284.0),
                StudyAllocationCostOffsetAdjuster(weight: 0.73),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 73864.6
        )
    }
}
