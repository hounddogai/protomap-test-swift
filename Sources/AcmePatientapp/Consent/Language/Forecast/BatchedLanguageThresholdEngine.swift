import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched language threshold calculation.
    protocol BatchedLanguageThresholdAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedLanguageThreshold, value: Double) -> Double
    }

    final class FlaggedBatchedLanguageThresholdAdjuster: BatchedLanguageThresholdAdjuster {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: BatchedLanguageThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedLanguageThresholdAdjuster: BatchedLanguageThresholdAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedLanguageThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapBatchedLanguageThresholdAdjuster: BatchedLanguageThresholdAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedLanguageThreshold, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedLanguageThresholdAdjuster: BatchedLanguageThresholdAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedLanguageThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched language threshold steps in order and keeps a trace of each.
    final class BatchedLanguageThresholdEngine {
        var steps: [any BatchedLanguageThresholdAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedLanguageThresholdAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedLanguageThreshold) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [BatchedLanguageThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedLanguageThresholdEngine(_ flags: Kit.Flags.Registry) -> BatchedLanguageThresholdEngine {
        return BatchedLanguageThresholdEngine(
            steps: [
                FlaggedBatchedLanguageThresholdAdjuster(
                    flags: flags,
                    flag: "batched-language-threshold-default",
                    percent: -5.9
                ),
                TieredBatchedLanguageThresholdAdjuster(bounds: [3016.0, 4074.0], rates: [1.05, 1.03]),
                CapBatchedLanguageThresholdAdjuster(cap: 15322.0),
                MinimumBatchedLanguageThresholdAdjuster(minimum: 41.9),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 81661.3
        )
    }
}
