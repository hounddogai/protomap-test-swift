import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot agreement calculation.
    protocol BatchedSlotAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double
    }

    final class BatchedSlotAgreementFloorValueOffsetAdjuster: BatchedSlotAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class RoundingBatchedSlotAgreementAdjuster: BatchedSlotAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentBatchedSlotAgreementAdjuster: BatchedSlotAgreementAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentBatchedSlotAgreementAdjuster: BatchedSlotAgreementAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapBatchedSlotAgreementAdjuster: BatchedSlotAgreementAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedSlotAgreementAdjuster: BatchedSlotAgreementAdjuster {
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

        func adjust(_ item: BatchedSlotAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched slot agreement steps in order and keeps a trace of each.
    final class BatchedSlotAgreementEngine {
        var steps: [any BatchedSlotAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedSlotAgreement) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedSlotAgreementAdjuster = steps[index]
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

        func evaluateAll(_ items: [BatchedSlotAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotAgreementEngine(_ flags: Kit.Flags.Registry) -> BatchedSlotAgreementEngine {
        return BatchedSlotAgreementEngine(
            steps: [
                BatchedSlotAgreementFloorValueOffsetAdjuster(weight: 1.58),
                RoundingBatchedSlotAgreementAdjuster(step: 0.05),
                PercentBatchedSlotAgreementAdjuster(percent: 3.7),
                SegmentBatchedSlotAgreementAdjuster(factors: ["west": 0.87, "retail": 1.3, "south": 0.9]),
                CapBatchedSlotAgreementAdjuster(cap: 18325.0),
                FlaggedBatchedSlotAgreementAdjuster(
                    flags: flags,
                    flag: "batched-slot-agreement-regional",
                    percent: 4.2
                ),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 84241.0
        )
    }
}
