import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched substitution digest calculation.
    protocol BatchedSubstitutionDigestAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double
    }

    final class PercentBatchedSubstitutionDigestAdjuster: BatchedSubstitutionDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedSubstitutionDigestAdjuster: BatchedSubstitutionDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BatchedSubstitutionDigestFloorValueOffsetAdjuster: BatchedSubstitutionDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredBatchedSubstitutionDigestAdjuster: BatchedSubstitutionDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedBatchedSubstitutionDigestAdjuster: BatchedSubstitutionDigestAdjuster {
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

        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardBatchedSubstitutionDigestAdjuster: BatchedSubstitutionDigestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: BatchedSubstitutionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched substitution digest steps in order and keeps a trace of each.
    final class BatchedSubstitutionDigestEngine {
        var steps: [any BatchedSubstitutionDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSubstitutionDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedSubstitutionDigest) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedSubstitutionDigestAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedSubstitutionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedSubstitutionDigestEngine(_ flags: Kit.Flags.Registry) -> BatchedSubstitutionDigestEngine {
        return BatchedSubstitutionDigestEngine(
            steps: [
                PercentBatchedSubstitutionDigestAdjuster(percent: 12.4),
                MinimumBatchedSubstitutionDigestAdjuster(minimum: 5.4),
                BatchedSubstitutionDigestFloorValueOffsetAdjuster(weight: 0.88),
                TieredBatchedSubstitutionDigestAdjuster(
                    bounds: [214.0, 1695.0, 4286.0, 7314.0],
                    rates: [0.86, 1.15, 0.84, 1.16]
                ),
                FlaggedBatchedSubstitutionDigestAdjuster(
                    flags: flags,
                    flag: "batched-substitution-digest-manual",
                    percent: 4.1
                ),
                WardBatchedSubstitutionDigestAdjuster(factors: ["east": 0.82, "north": 1.08]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 57312.0
        )
    }
}
