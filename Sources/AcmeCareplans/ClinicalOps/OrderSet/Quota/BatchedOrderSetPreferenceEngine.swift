import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the batched order set preference calculation.
    protocol BatchedOrderSetPreferenceModifier {
        func describe() -> String
        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double
    }

    final class TieredBatchedOrderSetPreferenceAdjuster: BatchedOrderSetPreferenceModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentBatchedOrderSetPreferenceAdjuster: BatchedOrderSetPreferenceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelBatchedOrderSetPreferenceAdjuster: BatchedOrderSetPreferenceModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedOrderSetPreferenceAdjuster: BatchedOrderSetPreferenceModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedBatchedOrderSetPreferenceAdjuster: BatchedOrderSetPreferenceModifier {
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

        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedOrderSetPreferenceAdjuster: BatchedOrderSetPreferenceModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedOrderSetPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched order set preference steps in order and keeps a trace of each.
    final class BatchedOrderSetPreferenceEngine {
        var steps: [any BatchedOrderSetPreferenceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOrderSetPreferenceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedOrderSetPreference) -> Double {
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

        func evaluateAll(_ items: [BatchedOrderSetPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedOrderSetPreferenceEngine(_ flags: Kit.Flags.Registry) -> BatchedOrderSetPreferenceEngine {
        return BatchedOrderSetPreferenceEngine(
            steps: [
                TieredBatchedOrderSetPreferenceAdjuster(bounds: [3724.0, 7356.0, 8401.0], rates: [0.94, 0.93, 0.94]),
                PercentBatchedOrderSetPreferenceAdjuster(percent: -0.2),
                ChannelBatchedOrderSetPreferenceAdjuster(factors: ["west": 0.72, "online": 1.24]),
                RoundingBatchedOrderSetPreferenceAdjuster(step: 0.05),
                FlaggedBatchedOrderSetPreferenceAdjuster(
                    flags: flags,
                    flag: "batched-order-set-preference-adaptive",
                    percent: -7.3
                ),
                MinimumBatchedOrderSetPreferenceAdjuster(minimum: 17.0),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 45429.2
        )
    }
}
