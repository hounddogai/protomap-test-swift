import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan score calculation.
    protocol DischargePlanScoreStep {
        func describe() -> String
        func adjust(_ item: DischargePlanScore, value: Double) -> Double
    }

    final class PercentDischargePlanScoreAdjuster: DischargePlanScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDischargePlanScoreAdjuster: DischargePlanScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentDischargePlanScoreAdjuster: DischargePlanScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DischargePlanScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the discharge plan score steps in order and keeps a trace of each.
    final class DischargePlanScoreEngine {
        var steps: [any DischargePlanScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanScore) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanScoreStep = steps[index]
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

        func evaluateAll(_ items: [DischargePlanScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanScoreEngine() -> DischargePlanScoreEngine {
        return DischargePlanScoreEngine(
            steps: [
                PercentDischargePlanScoreAdjuster(percent: -4.0),
                MinimumDischargePlanScoreAdjuster(minimum: 18.8),
                SegmentDischargePlanScoreAdjuster(factors: ["south": 1.36]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 89790.9
        )
    }
}
