import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched denial policy calculation.
    protocol BatchedDenialPolicyStep {
        func describe() -> String
        func adjust(_ item: BatchedDenialPolicy, value: Double) -> Double
    }

    final class RoundingBatchedDenialPolicyAdjuster: BatchedDenialPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedDenialPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleBatchedDenialPolicyAdjuster: BatchedDenialPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedDenialPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapBatchedDenialPolicyAdjuster: BatchedDenialPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedDenialPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedBatchedDenialPolicyAdjuster: BatchedDenialPolicyStep {
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

        func adjust(_ item: BatchedDenialPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the batched denial policy steps in order and keeps a trace of each.
    final class BatchedDenialPolicyEngine {
        var steps: [any BatchedDenialPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedDenialPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedDenialPolicy) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedDenialPolicyStep = steps[index]
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

        func evaluateAll(_ items: [BatchedDenialPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedDenialPolicyEngine(_ flags: Kit.Flags.Registry) -> BatchedDenialPolicyEngine {
        return BatchedDenialPolicyEngine(
            steps: [
                RoundingBatchedDenialPolicyAdjuster(step: 5.0),
                TitleBatchedDenialPolicyAdjuster(factors: ["north": 0.94, "central": 1.15]),
                CapBatchedDenialPolicyAdjuster(cap: 26131.0),
                FlaggedBatchedDenialPolicyAdjuster(flags: flags, flag: "batched-denial-policy-manual", percent: 6.7),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 14006.9
        )
    }
}
