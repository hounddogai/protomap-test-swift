import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted specimen milestone calculation.
    protocol WeightedSpecimenMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedSpecimenMilestone, value: Double) -> Double
    }

    final class WeightedSpecimenMilestoneScoreOffsetAdjuster: WeightedSpecimenMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: WeightedSpecimenMilestone, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentWeightedSpecimenMilestoneAdjuster: WeightedSpecimenMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSpecimenMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingWeightedSpecimenMilestoneAdjuster: WeightedSpecimenMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSpecimenMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the weighted specimen milestone steps in order and keeps a trace of each.
    final class WeightedSpecimenMilestoneEngine {
        var steps: [any WeightedSpecimenMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSpecimenMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedSpecimenMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedSpecimenMilestoneAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedSpecimenMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedSpecimenMilestoneEngine() -> WeightedSpecimenMilestoneEngine {
        return WeightedSpecimenMilestoneEngine(
            steps: [
                WeightedSpecimenMilestoneScoreOffsetAdjuster(weight: 0.77),
                PercentWeightedSpecimenMilestoneAdjuster(percent: -6.9),
                RoundingWeightedSpecimenMilestoneAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 17424.6
        )
    }
}
