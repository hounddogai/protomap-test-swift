import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the batched overtime mapping calculation.
    protocol BatchedOvertimeMappingAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedOvertimeMapping, value: Double) -> Double
    }

    final class FlaggedBatchedOvertimeMappingAdjuster: BatchedOvertimeMappingAdjuster {
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

        func adjust(_ item: BatchedOvertimeMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentBatchedOvertimeMappingAdjuster: BatchedOvertimeMappingAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedOvertimeMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingBatchedOvertimeMappingAdjuster: BatchedOvertimeMappingAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedOvertimeMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelBatchedOvertimeMappingAdjuster: BatchedOvertimeMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: BatchedOvertimeMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched overtime mapping steps in order and keeps a trace of each.
    final class BatchedOvertimeMappingEngine {
        var steps: [any BatchedOvertimeMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedOvertimeMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedOvertimeMapping) -> Double {
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

        func evaluateAll(_ items: [BatchedOvertimeMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedOvertimeMappingEngine(_ flags: Kit.Flags.Registry) -> BatchedOvertimeMappingEngine {
        return BatchedOvertimeMappingEngine(
            steps: [
                FlaggedBatchedOvertimeMappingAdjuster(
                    flags: flags,
                    flag: "batched-overtime-mapping-seasonal",
                    percent: -5.6
                ),
                PercentBatchedOvertimeMappingAdjuster(percent: -18.5),
                RoundingBatchedOvertimeMappingAdjuster(step: 0.05),
                LabelBatchedOvertimeMappingAdjuster(factors: ["online": 1.07]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 21985.5
        )
    }
}
