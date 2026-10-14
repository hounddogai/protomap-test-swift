import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan batch calculation.
    protocol DischargePlanBatchAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanBatch, value: Double) -> Double
    }

    final class PercentDischargePlanBatchAdjuster: DischargePlanBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDischargePlanBatchAdjuster: DischargePlanBatchAdjuster {
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

        func adjust(_ item: DischargePlanBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DischargePlanBatchSequenceOffsetAdjuster: DischargePlanBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DischargePlanBatch, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class CapDischargePlanBatchAdjuster: DischargePlanBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelDischargePlanBatchAdjuster: DischargePlanBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DischargePlanBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the discharge plan batch steps in order and keeps a trace of each.
    final class DischargePlanBatchEngine {
        var steps: [any DischargePlanBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DischargePlanBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [DischargePlanBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanBatchEngine(_ flags: Kit.Flags.Registry) -> DischargePlanBatchEngine {
        return DischargePlanBatchEngine(
            steps: [
                PercentDischargePlanBatchAdjuster(percent: -19.0),
                FlaggedDischargePlanBatchAdjuster(flags: flags, flag: "discharge-plan-batch-regional", percent: -7.4),
                DischargePlanBatchSequenceOffsetAdjuster(weight: 0.68),
                CapDischargePlanBatchAdjuster(cap: 920.0),
                LabelDischargePlanBatchAdjuster(factors: ["west": 1.07, "north": 1.14, "central": 1.05]),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 72195.8
        )
    }
}
