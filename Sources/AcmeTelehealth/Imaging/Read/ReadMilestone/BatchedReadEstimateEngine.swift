import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the batched read estimate calculation.
    protocol BatchedReadEstimateAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double
    }

    final class CapBatchedReadEstimateAdjuster: BatchedReadEstimateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedReadEstimateAdjuster: BatchedReadEstimateAdjuster {
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

        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceBatchedReadEstimateAdjuster: BatchedReadEstimateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class BatchedReadEstimateScoreOffsetAdjuster: BatchedReadEstimateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class PercentBatchedReadEstimateAdjuster: BatchedReadEstimateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredBatchedReadEstimateAdjuster: BatchedReadEstimateAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedReadEstimate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the batched read estimate steps in order and keeps a trace of each.
    final class BatchedReadEstimateEngine {
        var steps: [any BatchedReadEstimateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedReadEstimateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedReadEstimate) -> Double {
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

        func evaluateAll(_ items: [BatchedReadEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedReadEstimateEngine(_ flags: Kit.Flags.Registry) -> BatchedReadEstimateEngine {
        return BatchedReadEstimateEngine(
            steps: [
                CapBatchedReadEstimateAdjuster(cap: 12146.0),
                FlaggedBatchedReadEstimateAdjuster(
                    flags: flags,
                    flag: "batched-read-estimate-scheduled",
                    percent: 3.9
                ),
                SourceBatchedReadEstimateAdjuster(factors: ["east": 0.88, "online": 1.01, "retail": 1.39]),
                BatchedReadEstimateScoreOffsetAdjuster(weight: 0.82),
                PercentBatchedReadEstimateAdjuster(percent: -16.5),
                TieredBatchedReadEstimateAdjuster(bounds: [7366.0, 9978.0], rates: [0.96, 1.09]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 75171.0
        )
    }
}
