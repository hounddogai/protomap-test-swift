import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the batched cleaning digest calculation.
    protocol BatchedCleaningDigestStep {
        func describe() -> String
        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double
    }

    final class TieredBatchedCleaningDigestAdjuster: BatchedCleaningDigestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelBatchedCleaningDigestAdjuster: BatchedCleaningDigestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedCleaningDigestAdjuster: BatchedCleaningDigestStep {
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

        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedCleaningDigestAdjuster: BatchedCleaningDigestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedCleaningDigestAdjuster: BatchedCleaningDigestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedCleaningDigestLimitOffsetAdjuster: BatchedCleaningDigestStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: BatchedCleaningDigest, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the batched cleaning digest steps in order and keeps a trace of each.
    final class BatchedCleaningDigestEngine {
        var steps: [any BatchedCleaningDigestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedCleaningDigestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedCleaningDigest) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [BatchedCleaningDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedCleaningDigestEngine(_ flags: Kit.Flags.Registry) -> BatchedCleaningDigestEngine {
        return BatchedCleaningDigestEngine(
            steps: [
                TieredBatchedCleaningDigestAdjuster(bounds: [1473.0, 5044.0, 8737.0], rates: [0.82, 0.8, 1.15]),
                LabelBatchedCleaningDigestAdjuster(factors: ["south": 0.87, "online": 0.85]),
                FlaggedBatchedCleaningDigestAdjuster(
                    flags: flags,
                    flag: "batched-cleaning-digest-scheduled",
                    percent: 7.4
                ),
                CapBatchedCleaningDigestAdjuster(cap: 37592.0),
                PercentBatchedCleaningDigestAdjuster(percent: 19.2),
                BatchedCleaningDigestLimitOffsetAdjuster(weight: 1.79),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 61334.7
        )
    }
}
