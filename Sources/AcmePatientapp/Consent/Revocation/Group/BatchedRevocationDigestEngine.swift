import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched revocation digest calculation.
    protocol BatchedRevocationDigestFactor {
        func describe() -> String
        func adjust(_ item: BatchedRevocationDigest, value: Double) -> Double
    }

    final class TieredBatchedRevocationDigestAdjuster: BatchedRevocationDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRevocationDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedRevocationDigestAdjuster: BatchedRevocationDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedRevocationDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumBatchedRevocationDigestAdjuster: BatchedRevocationDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedRevocationDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched revocation digest steps in order and keeps a trace of each.
    final class BatchedRevocationDigestEngine {
        var steps: [any BatchedRevocationDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRevocationDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedRevocationDigest) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedRevocationDigestFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedRevocationDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedRevocationDigestEngine() -> BatchedRevocationDigestEngine {
        return BatchedRevocationDigestEngine(
            steps: [
                TieredBatchedRevocationDigestAdjuster(
                    bounds: [585.0, 1174.0, 6034.0, 8731.0],
                    rates: [0.87, 0.85, 1.0, 0.93]
                ),
                RoundingBatchedRevocationDigestAdjuster(step: 5.0),
                MinimumBatchedRevocationDigestAdjuster(minimum: 44.9),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 79545.0
        )
    }
}
