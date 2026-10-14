import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched slot template calculation.
    protocol BatchedSlotTemplateFactor {
        func describe() -> String
        func adjust(_ item: BatchedSlotTemplate, value: Double) -> Double
    }

    final class MinimumBatchedSlotTemplateAdjuster: BatchedSlotTemplateFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedSlotTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceBatchedSlotTemplateAdjuster: BatchedSlotTemplateFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: BatchedSlotTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedBatchedSlotTemplateAdjuster: BatchedSlotTemplateFactor {
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

        func adjust(_ item: BatchedSlotTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapBatchedSlotTemplateAdjuster: BatchedSlotTemplateFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedSlotTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the batched slot template steps in order and keeps a trace of each.
    final class BatchedSlotTemplateEngine {
        var steps: [any BatchedSlotTemplateFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedSlotTemplateFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedSlotTemplate) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedSlotTemplateFactor = steps[index]
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

        func evaluateAll(_ items: [BatchedSlotTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedSlotTemplateEngine(_ flags: Kit.Flags.Registry) -> BatchedSlotTemplateEngine {
        return BatchedSlotTemplateEngine(
            steps: [
                MinimumBatchedSlotTemplateAdjuster(minimum: 9.6),
                SourceBatchedSlotTemplateAdjuster(factors: ["west": 0.73, "central": 1.07, "online": 0.77]),
                FlaggedBatchedSlotTemplateAdjuster(flags: flags, flag: "batched-slot-template-strict", percent: -9.2),
                CapBatchedSlotTemplateAdjuster(cap: 40820.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 53815.1
        )
    }
}
