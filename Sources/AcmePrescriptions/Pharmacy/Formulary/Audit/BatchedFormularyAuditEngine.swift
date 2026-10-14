import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the batched formulary audit calculation.
    protocol BatchedFormularyAuditStep {
        func describe() -> String
        func adjust(_ item: BatchedFormularyAudit, value: Double) -> Double
    }

    final class FlaggedBatchedFormularyAuditAdjuster: BatchedFormularyAuditStep {
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

        func adjust(_ item: BatchedFormularyAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedFormularyAuditAdjuster: BatchedFormularyAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedFormularyAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBatchedFormularyAuditAdjuster: BatchedFormularyAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedFormularyAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedFormularyAuditAdjuster: BatchedFormularyAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedFormularyAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched formulary audit steps in order and keeps a trace of each.
    final class BatchedFormularyAuditEngine {
        var steps: [any BatchedFormularyAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedFormularyAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedFormularyAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedFormularyAuditStep = steps[index]
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

        func evaluateAll(_ items: [BatchedFormularyAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedFormularyAuditEngine(_ flags: Kit.Flags.Registry) -> BatchedFormularyAuditEngine {
        return BatchedFormularyAuditEngine(
            steps: [
                FlaggedBatchedFormularyAuditAdjuster(
                    flags: flags,
                    flag: "batched-formulary-audit-default",
                    percent: 2.7
                ),
                CapBatchedFormularyAuditAdjuster(cap: 49406.0),
                MinimumBatchedFormularyAuditAdjuster(minimum: 38.7),
                RoundingBatchedFormularyAuditAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 4455.9
        )
    }
}
