import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim batch calculation.
    protocol ClaimBatchFactor {
        func describe() -> String
        func adjust(_ item: ClaimBatch, value: Double) -> Double
    }

    final class MinimumClaimBatchAdjuster: ClaimBatchFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingClaimBatchAdjuster: ClaimBatchFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredClaimBatchAdjuster: ClaimBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the claim batch steps in order and keeps a trace of each.
    final class ClaimBatchEngine {
        var steps: [any ClaimBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimBatch) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimBatchFactor = steps[index]
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

        func evaluateAll(_ items: [ClaimBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimBatchEngine() -> ClaimBatchEngine {
        return ClaimBatchEngine(
            steps: [
                MinimumClaimBatchAdjuster(minimum: 41.9),
                RoundingClaimBatchAdjuster(step: 5.0),
                TieredClaimBatchAdjuster(bounds: [30.0, 6196.0], rates: [0.82, 0.99]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 50564.5
        )
    }
}
