import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched language bundle calculation.
    protocol BatchedLanguageBundleAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedLanguageBundle, value: Double) -> Double
    }

    final class MinimumBatchedLanguageBundleAdjuster: BatchedLanguageBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedLanguageBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedLanguageBundleAdjuster: BatchedLanguageBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedLanguageBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedLanguageBundleAdjuster: BatchedLanguageBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedLanguageBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched language bundle steps in order and keeps a trace of each.
    final class BatchedLanguageBundleEngine {
        var steps: [any BatchedLanguageBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedLanguageBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedLanguageBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedLanguageBundleAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedLanguageBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedLanguageBundleEngine() -> BatchedLanguageBundleEngine {
        return BatchedLanguageBundleEngine(
            steps: [
                MinimumBatchedLanguageBundleAdjuster(minimum: 31.0),
                TieredBatchedLanguageBundleAdjuster(
                    bounds: [5959.0, 7511.0, 8563.0, 9814.0],
                    rates: [0.97, 1.16, 0.9, 1.05]
                ),
                PercentBatchedLanguageBundleAdjuster(percent: -8.5),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 57450.8
        )
    }
}
