import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched care gap estimate calculation.
    protocol BatchedCareGapEstimateStep {
        func describe() -> String
        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double
    }

    final class PercentBatchedCareGapEstimateAdjuster: BatchedCareGapEstimateStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelBatchedCareGapEstimateAdjuster: BatchedCareGapEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumBatchedCareGapEstimateAdjuster: BatchedCareGapEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredBatchedCareGapEstimateAdjuster: BatchedCareGapEstimateStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapBatchedCareGapEstimateAdjuster: BatchedCareGapEstimateStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedCareGapEstimateAdjuster: BatchedCareGapEstimateStep {
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

        func adjust(_ item: BatchedCareGapEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched care gap estimate steps in order and keeps a trace of each.
    final class BatchedCareGapEstimateEngine {
        var steps: [any BatchedCareGapEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCareGapEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedCareGapEstimate) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [BatchedCareGapEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedCareGapEstimateEngine(_ flags: Kit.Flags.Registry) -> BatchedCareGapEstimateEngine {
        return BatchedCareGapEstimateEngine(
            steps: [
                PercentBatchedCareGapEstimateAdjuster(percent: -7.5),
                LabelBatchedCareGapEstimateAdjuster(factors: ["east": 1.29, "west": 1.02, "retail": 0.91]),
                MinimumBatchedCareGapEstimateAdjuster(minimum: 28.0),
                TieredBatchedCareGapEstimateAdjuster(bounds: [4629.0, 8328.0, 9099.0], rates: [1.0, 1.06, 0.96]),
                CapBatchedCareGapEstimateAdjuster(cap: 11179.0),
                FlaggedBatchedCareGapEstimateAdjuster(
                    flags: flags,
                    flag: "batched-care-gap-estimate-weighted",
                    percent: 5.2
                ),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 2398.8
        )
    }
}
