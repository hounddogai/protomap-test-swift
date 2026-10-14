import AcmePlatform
import Foundation

extension Labs {
    /// One step of the batched accession estimate calculation.
    protocol BatchedAccessionEstimateStep {
        func describe() -> String
        func adjust(_ item: BatchedAccessionEstimate, value: Double) -> Double
    }

    final class CapBatchedAccessionEstimateAdjuster: BatchedAccessionEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedAccessionEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedAccessionEstimateAdjuster: BatchedAccessionEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedAccessionEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedAccessionEstimateAdjuster: BatchedAccessionEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedAccessionEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched accession estimate steps in order and keeps a trace of each.
    final class BatchedAccessionEstimateEngine {
        var steps: [any BatchedAccessionEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAccessionEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedAccessionEstimate) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedAccessionEstimateStep = steps[index]
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

        func evaluateAll(_ items: [BatchedAccessionEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedAccessionEstimateEngine() -> BatchedAccessionEstimateEngine {
        return BatchedAccessionEstimateEngine(
            steps: [
                CapBatchedAccessionEstimateAdjuster(cap: 43201.0),
                TieredBatchedAccessionEstimateAdjuster(
                    bounds: [3010.0, 5586.0, 7386.0, 8682.0],
                    rates: [0.86, 0.9, 0.94, 0.92]
                ),
                PercentBatchedAccessionEstimateAdjuster(percent: 5.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 26638.7
        )
    }
}
