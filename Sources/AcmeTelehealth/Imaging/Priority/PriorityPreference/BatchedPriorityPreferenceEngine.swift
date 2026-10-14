import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched priority preference calculation.
    protocol BatchedPriorityPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double
    }

    final class CapBatchedPriorityPreferenceAdjuster: BatchedPriorityPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedPriorityPreferenceAdjuster: BatchedPriorityPreferenceAdjuster {
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

        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameBatchedPriorityPreferenceAdjuster: BatchedPriorityPreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedPriorityPreferenceAdjuster: BatchedPriorityPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentBatchedPriorityPreferenceAdjuster: BatchedPriorityPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedPriorityPreferenceAdjuster: BatchedPriorityPreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedPriorityPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched priority preference steps in order and keeps a trace of each.
    final class BatchedPriorityPreferenceEngine {
        var steps: [any BatchedPriorityPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedPriorityPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedPriorityPreference) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [BatchedPriorityPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedPriorityPreferenceEngine(_ flags: Kit.Flags.Registry) -> BatchedPriorityPreferenceEngine {
        return BatchedPriorityPreferenceEngine(
            steps: [
                CapBatchedPriorityPreferenceAdjuster(cap: 8658.0),
                FlaggedBatchedPriorityPreferenceAdjuster(
                    flags: flags,
                    flag: "batched-priority-preference-default",
                    percent: 6.3
                ),
                NameBatchedPriorityPreferenceAdjuster(factors: ["central": 1.32, "east": 1.33]),
                RoundingBatchedPriorityPreferenceAdjuster(step: 1.0),
                PercentBatchedPriorityPreferenceAdjuster(percent: -13.9),
                TieredBatchedPriorityPreferenceAdjuster(bounds: [1662.0, 7393.0], rates: [1.14, 0.86]),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 62857.9
        )
    }
}
