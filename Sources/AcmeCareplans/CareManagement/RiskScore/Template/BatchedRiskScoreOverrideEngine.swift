import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched risk score override calculation.
    protocol BatchedRiskScoreOverrideModifier {
        func describe() -> String
        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double
    }

    final class TieredBatchedRiskScoreOverrideAdjuster: BatchedRiskScoreOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapBatchedRiskScoreOverrideAdjuster: BatchedRiskScoreOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedRiskScoreOverrideAdjuster: BatchedRiskScoreOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBatchedRiskScoreOverrideAdjuster: BatchedRiskScoreOverrideModifier {
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

        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedRiskScoreOverrideCapacityOffsetAdjuster: BatchedRiskScoreOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class LabelBatchedRiskScoreOverrideAdjuster: BatchedRiskScoreOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedRiskScoreOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched risk score override steps in order and keeps a trace of each.
    final class BatchedRiskScoreOverrideEngine {
        var steps: [any BatchedRiskScoreOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedRiskScoreOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: BatchedRiskScoreOverride) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [BatchedRiskScoreOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultBatchedRiskScoreOverrideEngine(_ flags: Kit.Flags.Registry) -> BatchedRiskScoreOverrideEngine {
        return BatchedRiskScoreOverrideEngine(
            steps: [
                TieredBatchedRiskScoreOverrideAdjuster(bounds: [1172.0, 2887.0, 4466.0], rates: [0.82, 1.13, 1.07]),
                CapBatchedRiskScoreOverrideAdjuster(cap: 15296.0),
                PercentBatchedRiskScoreOverrideAdjuster(percent: -13.2),
                FlaggedBatchedRiskScoreOverrideAdjuster(
                    flags: flags,
                    flag: "batched-risk-score-override-capped",
                    percent: -4.8
                ),
                BatchedRiskScoreOverrideCapacityOffsetAdjuster(weight: 1.67),
                LabelBatchedRiskScoreOverrideAdjuster(factors: ["online": 1.03, "west": 1.33]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 75148.6
        )
    }
}
