import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched authorization snapshot calculation.
    protocol BatchedAuthorizationSnapshotStep {
        func describe() -> String
        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double
    }

    final class TitleBatchedAuthorizationSnapshotAdjuster: BatchedAuthorizationSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedAuthorizationSnapshotAdjuster: BatchedAuthorizationSnapshotStep {
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

        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedAuthorizationSnapshotAdjuster: BatchedAuthorizationSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapBatchedAuthorizationSnapshotAdjuster: BatchedAuthorizationSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class BatchedAuthorizationSnapshotScoreOffsetAdjuster: BatchedAuthorizationSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumBatchedAuthorizationSnapshotAdjuster: BatchedAuthorizationSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedAuthorizationSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the batched authorization snapshot steps in order and keeps a trace of each.
    final class BatchedAuthorizationSnapshotEngine {
        var steps: [any BatchedAuthorizationSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedAuthorizationSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedAuthorizationSnapshot) -> Double {
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

        func evaluateAll(_ items: [BatchedAuthorizationSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedAuthorizationSnapshotEngine(_ flags: Kit.Flags.Registry) -> BatchedAuthorizationSnapshotEngine {
        return BatchedAuthorizationSnapshotEngine(
            steps: [
                TitleBatchedAuthorizationSnapshotAdjuster(factors: ["east": 0.93]),
                FlaggedBatchedAuthorizationSnapshotAdjuster(
                    flags: flags,
                    flag: "batched-authorization-snapshot-global",
                    percent: 4.2
                ),
                RoundingBatchedAuthorizationSnapshotAdjuster(step: 0.05),
                CapBatchedAuthorizationSnapshotAdjuster(cap: 9009.0),
                BatchedAuthorizationSnapshotScoreOffsetAdjuster(weight: 0.84),
                MinimumBatchedAuthorizationSnapshotAdjuster(minimum: 24.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 73193.2
        )
    }
}
