import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession milestone calculation.
    protocol AccessionMilestoneAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionMilestone, value: Double) -> Double
    }

    final class NameAccessionMilestoneAdjuster: AccessionMilestoneAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AccessionMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAccessionMilestoneAdjuster: AccessionMilestoneAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAccessionMilestoneAdjuster: AccessionMilestoneAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AccessionMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapAccessionMilestoneAdjuster: AccessionMilestoneAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AccessionMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AccessionMilestoneWeightOffsetAdjuster: AccessionMilestoneAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: AccessionMilestone, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class PercentAccessionMilestoneAdjuster: AccessionMilestoneAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession milestone steps in order and keeps a trace of each.
    final class AccessionMilestoneEngine {
        var steps: [any AccessionMilestoneAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionMilestoneAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AccessionMilestone) -> Double {
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

        func evaluateAll(_ items: [AccessionMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAccessionMilestoneEngine() -> AccessionMilestoneEngine {
        return AccessionMilestoneEngine(
            steps: [
                NameAccessionMilestoneAdjuster(factors: ["central": 0.97, "east": 1.0, "north": 1.18]),
                MinimumAccessionMilestoneAdjuster(minimum: 6.1),
                RoundingAccessionMilestoneAdjuster(step: 5.0),
                CapAccessionMilestoneAdjuster(cap: 6284.0),
                AccessionMilestoneWeightOffsetAdjuster(weight: 1.96),
                PercentAccessionMilestoneAdjuster(percent: -20.1),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 77876.9
        )
    }
}
