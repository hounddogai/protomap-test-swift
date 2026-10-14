import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched formulary bundle calculation.
    protocol BatchedFormularyBundleFactor {
        func describe() -> String
        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double
    }

    final class CapBatchedFormularyBundleAdjuster: BatchedFormularyBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredBatchedFormularyBundleAdjuster: BatchedFormularyBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedFormularyBundleAdjuster: BatchedFormularyBundleFactor {
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

        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedFormularyBundleRetriesOffsetAdjuster: BatchedFormularyBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class FacilityBatchedFormularyBundleAdjuster: BatchedFormularyBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentBatchedFormularyBundleAdjuster: BatchedFormularyBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedFormularyBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched formulary bundle steps in order and keeps a trace of each.
    final class BatchedFormularyBundleEngine {
        var steps: [any BatchedFormularyBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedFormularyBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedFormularyBundle) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedFormularyBundleFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedFormularyBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedFormularyBundleEngine(_ flags: Kit.Flags.Registry) -> BatchedFormularyBundleEngine {
        return BatchedFormularyBundleEngine(
            steps: [
                CapBatchedFormularyBundleAdjuster(cap: 13754.0),
                TieredBatchedFormularyBundleAdjuster(
                    bounds: [1849.0, 2894.0, 3114.0, 6557.0],
                    rates: [0.8, 1.14, 1.19, 0.99]
                ),
                FlaggedBatchedFormularyBundleAdjuster(
                    flags: flags,
                    flag: "batched-formulary-bundle-weighted",
                    percent: 8.6
                ),
                BatchedFormularyBundleRetriesOffsetAdjuster(weight: 1.89),
                FacilityBatchedFormularyBundleAdjuster(factors: ["retail": 0.86]),
                PercentBatchedFormularyBundleAdjuster(percent: 0.1),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 22636.1
        )
    }
}
