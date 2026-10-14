import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched closure score calculation.
    protocol BatchedClosureScoreFactor {
        func describe() -> String
        func adjust(_ item: BatchedClosureScore, value: Double) -> Double
    }

    final class PercentBatchedClosureScoreAdjuster: BatchedClosureScoreFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedClosureScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedClosureScoreAdjuster: BatchedClosureScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedClosureScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredBatchedClosureScoreAdjuster: BatchedClosureScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedClosureScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched closure score steps in order and keeps a trace of each.
    final class BatchedClosureScoreEngine {
        var steps: [any BatchedClosureScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedClosureScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedClosureScore) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [BatchedClosureScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedClosureScoreEngine() -> BatchedClosureScoreEngine {
        return BatchedClosureScoreEngine(
            steps: [
                PercentBatchedClosureScoreAdjuster(percent: 12.9),
                RoundingBatchedClosureScoreAdjuster(step: 0.25),
                TieredBatchedClosureScoreAdjuster(bounds: [5364.0, 7269.0], rates: [1.0, 1.12]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 2463.6
        )
    }
}
