import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall baseline calculation.
    protocol RecallBaselineStep {
        func describe() -> String
        func adjust(_ item: RecallBaseline, value: Double) -> Double
    }

    final class MinimumRecallBaselineAdjuster: RecallBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleRecallBaselineAdjuster: RecallBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RecallBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRecallBaselineAdjuster: RecallBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RecallBaselineMaximumOffsetAdjuster: RecallBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RecallBaseline, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class TieredRecallBaselineAdjuster: RecallBaselineStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRecallBaselineAdjuster: RecallBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the recall baseline steps in order and keeps a trace of each.
    final class RecallBaselineEngine {
        var steps: [any RecallBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallBaseline) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallBaselineStep = steps[index]
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

        func evaluateAll(_ items: [RecallBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallBaselineEngine() -> RecallBaselineEngine {
        return RecallBaselineEngine(
            steps: [
                MinimumRecallBaselineAdjuster(minimum: 47.3),
                TitleRecallBaselineAdjuster(factors: ["east": 0.78]),
                CapRecallBaselineAdjuster(cap: 49889.0),
                RecallBaselineMaximumOffsetAdjuster(weight: 1.04),
                TieredRecallBaselineAdjuster(bounds: [1533.0, 2153.0, 5743.0], rates: [1.19, 1.06, 1.04]),
                RoundingRecallBaselineAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 54082.5
        )
    }
}
