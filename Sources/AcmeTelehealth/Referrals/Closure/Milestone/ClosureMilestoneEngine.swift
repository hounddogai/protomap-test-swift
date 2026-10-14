import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure milestone calculation.
    protocol ClosureMilestoneStep {
        func describe() -> String
        func adjust(_ item: ClosureMilestone, value: Double) -> Double
    }

    final class ClosureMilestoneScoreOffsetAdjuster: ClosureMilestoneStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ClosureMilestone, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentClosureMilestoneAdjuster: ClosureMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClosureMilestoneAdjuster: ClosureMilestoneStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClosureMilestone, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleClosureMilestoneAdjuster: ClosureMilestoneStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ClosureMilestone, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingClosureMilestoneAdjuster: ClosureMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClosureMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the closure milestone steps in order and keeps a trace of each.
    final class ClosureMilestoneEngine {
        var steps: [any ClosureMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ClosureMilestone) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ClosureMilestoneStep = steps[index]
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

        func evaluateAll(_ items: [ClosureMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultClosureMilestoneEngine() -> ClosureMilestoneEngine {
        return ClosureMilestoneEngine(
            steps: [
                ClosureMilestoneScoreOffsetAdjuster(weight: 1.56),
                PercentClosureMilestoneAdjuster(percent: 5.7),
                TieredClosureMilestoneAdjuster(
                    bounds: [1719.0, 3466.0, 4826.0, 9965.0],
                    rates: [0.8, 0.96, 1.09, 1.07]
                ),
                TitleClosureMilestoneAdjuster(factors: ["west": 1.22, "central": 1.06, "south": 0.91]),
                RoundingClosureMilestoneAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 58440.4
        )
    }
}
