import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched alert score calculation.
    protocol BatchedAlertScoreStep {
        func describe() -> String
        func adjust(_ item: BatchedAlertScore, value: Double) -> Double
    }

    final class CapBatchedAlertScoreAdjuster: BatchedAlertScoreStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedAlertScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedAlertScoreAdjuster: BatchedAlertScoreStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedAlertScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedAlertScoreAdjuster: BatchedAlertScoreStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedAlertScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedAlertScoreAdjuster: BatchedAlertScoreStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedAlertScore, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched alert score steps in order and keeps a trace of each.
    final class BatchedAlertScoreEngine {
        var steps: [any BatchedAlertScoreStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAlertScoreStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedAlertScore) -> Double {
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

        func evaluateAll(_ items: [BatchedAlertScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedAlertScoreEngine() -> BatchedAlertScoreEngine {
        return BatchedAlertScoreEngine(
            steps: [
                CapBatchedAlertScoreAdjuster(cap: 24759.0),
                MinimumBatchedAlertScoreAdjuster(minimum: 13.2),
                TieredBatchedAlertScoreAdjuster(
                    bounds: [3135.0, 6427.0, 8506.0, 9457.0],
                    rates: [1.02, 0.97, 1.11, 1.02]
                ),
                PercentBatchedAlertScoreAdjuster(percent: 5.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 79431.1
        )
    }
}
