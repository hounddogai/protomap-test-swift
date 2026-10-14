import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched witness quota calculation.
    protocol BatchedWitnessQuotaStep {
        func describe() -> String
        func adjust(_ item: BatchedWitnessQuota, value: Double) -> Double
    }

    final class FlaggedBatchedWitnessQuotaAdjuster: BatchedWitnessQuotaStep {
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

        func adjust(_ item: BatchedWitnessQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedWitnessQuotaAdjuster: BatchedWitnessQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedWitnessQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingBatchedWitnessQuotaAdjuster: BatchedWitnessQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedWitnessQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class BatchedWitnessQuotaAcuityOffsetAdjuster: BatchedWitnessQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: BatchedWitnessQuota, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class PercentBatchedWitnessQuotaAdjuster: BatchedWitnessQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedWitnessQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched witness quota steps in order and keeps a trace of each.
    final class BatchedWitnessQuotaEngine {
        var steps: [any BatchedWitnessQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedWitnessQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedWitnessQuota) -> Double {
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

        func evaluateAll(_ items: [BatchedWitnessQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedWitnessQuotaEngine(_ flags: Kit.Flags.Registry) -> BatchedWitnessQuotaEngine {
        return BatchedWitnessQuotaEngine(
            steps: [
                FlaggedBatchedWitnessQuotaAdjuster(flags: flags, flag: "batched-witness-quota-adaptive", percent: 4.3),
                CapBatchedWitnessQuotaAdjuster(cap: 6552.0),
                RoundingBatchedWitnessQuotaAdjuster(step: 1.0),
                BatchedWitnessQuotaAcuityOffsetAdjuster(weight: 1.06),
                PercentBatchedWitnessQuotaAdjuster(percent: -8.6),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 70485.1
        )
    }
}
