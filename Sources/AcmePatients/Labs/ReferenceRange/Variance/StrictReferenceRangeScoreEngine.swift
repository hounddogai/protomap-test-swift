import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict reference range score calculation.
    protocol StrictReferenceRangeScoreStep {
        func describe() -> String
        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double
    }

    final class CapStrictReferenceRangeScoreAdjuster: StrictReferenceRangeScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictReferenceRangeScoreBudgetOffsetAdjuster: StrictReferenceRangeScoreStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class PercentStrictReferenceRangeScoreAdjuster: StrictReferenceRangeScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictReferenceRangeScoreAdjuster: StrictReferenceRangeScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingStrictReferenceRangeScoreAdjuster: StrictReferenceRangeScoreStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelStrictReferenceRangeScoreAdjuster: StrictReferenceRangeScoreStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictReferenceRangeScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict reference range score steps in order and keeps a trace of each.
    final class StrictReferenceRangeScoreEngine {
        var steps: [any StrictReferenceRangeScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReferenceRangeScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictReferenceRangeScore) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictReferenceRangeScoreStep = steps[index]
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

        func evaluateAll(_ items: [StrictReferenceRangeScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictReferenceRangeScoreEngine() -> StrictReferenceRangeScoreEngine {
        return StrictReferenceRangeScoreEngine(
            steps: [
                CapStrictReferenceRangeScoreAdjuster(cap: 40759.0),
                StrictReferenceRangeScoreBudgetOffsetAdjuster(weight: 0.22),
                PercentStrictReferenceRangeScoreAdjuster(percent: -14.8),
                TieredStrictReferenceRangeScoreAdjuster(bounds: [511.0, 2468.0, 6887.0], rates: [0.89, 0.95, 0.87]),
                RoundingStrictReferenceRangeScoreAdjuster(step: 0.1),
                LabelStrictReferenceRangeScoreAdjuster(factors: ["north": 1.11, "retail": 1.37, "online": 1.14]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 10263.9
        )
    }
}
