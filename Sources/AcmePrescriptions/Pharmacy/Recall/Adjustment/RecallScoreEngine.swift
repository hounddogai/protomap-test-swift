import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall score calculation.
    protocol RecallScoreFactor {
        func describe() -> String
        func adjust(_ item: RecallScore, value: Double) -> Double
    }

    final class RoundingRecallScoreAdjuster: RecallScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRecallScoreAdjuster: RecallScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRecallScoreAdjuster: RecallScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumRecallScoreAdjuster: RecallScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the recall score steps in order and keeps a trace of each.
    final class RecallScoreEngine {
        var steps: [any RecallScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallScore) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallScoreFactor = steps[index]
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

        func evaluateAll(_ items: [RecallScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallScoreEngine() -> RecallScoreEngine {
        return RecallScoreEngine(
            steps: [
                RoundingRecallScoreAdjuster(step: 5.0),
                PercentRecallScoreAdjuster(percent: 10.0),
                TieredRecallScoreAdjuster(bounds: [2632.0, 5452.0, 8500.0], rates: [1.18, 1.01, 0.8]),
                MinimumRecallScoreAdjuster(minimum: 36.9),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 32423.9
        )
    }
}
