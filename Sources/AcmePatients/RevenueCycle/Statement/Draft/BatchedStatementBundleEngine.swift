import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched statement bundle calculation.
    protocol BatchedStatementBundleFactor {
        func describe() -> String
        func adjust(_ item: BatchedStatementBundle, value: Double) -> Double
    }

    final class BatchedStatementBundleEndsAtOffsetAdjuster: BatchedStatementBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: BatchedStatementBundle, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedBatchedStatementBundleAdjuster: BatchedStatementBundleFactor {
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

        func adjust(_ item: BatchedStatementBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumBatchedStatementBundleAdjuster: BatchedStatementBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStatementBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapBatchedStatementBundleAdjuster: BatchedStatementBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedStatementBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedStatementBundleAdjuster: BatchedStatementBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedStatementBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched statement bundle steps in order and keeps a trace of each.
    final class BatchedStatementBundleEngine {
        var steps: [any BatchedStatementBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStatementBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedStatementBundle) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [BatchedStatementBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedStatementBundleEngine(_ flags: Kit.Flags.Registry) -> BatchedStatementBundleEngine {
        return BatchedStatementBundleEngine(
            steps: [
                BatchedStatementBundleEndsAtOffsetAdjuster(weight: 1.45),
                FlaggedBatchedStatementBundleAdjuster(
                    flags: flags,
                    flag: "batched-statement-bundle-scheduled",
                    percent: -9.0
                ),
                MinimumBatchedStatementBundleAdjuster(minimum: 4.2),
                CapBatchedStatementBundleAdjuster(cap: 14609.0),
                PercentBatchedStatementBundleAdjuster(percent: -12.2),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 62509.6
        )
    }
}
