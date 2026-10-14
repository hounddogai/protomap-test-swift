import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall adjustment calculation.
    protocol RecallAdjustmentStep {
        func describe() -> String
        func adjust(_ item: RecallAdjustment, value: Double) -> Double
    }

    final class MinimumRecallAdjustmentAdjuster: RecallAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RecallAdjustmentRetriesOffsetAdjuster: RecallAdjustmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: RecallAdjustment, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class CategoryRecallAdjustmentAdjuster: RecallAdjustmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RecallAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRecallAdjustmentAdjuster: RecallAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRecallAdjustmentAdjuster: RecallAdjustmentStep {
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

        func adjust(_ item: RecallAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRecallAdjustmentAdjuster: RecallAdjustmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the recall adjustment steps in order and keeps a trace of each.
    final class RecallAdjustmentEngine {
        var steps: [any RecallAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RecallAdjustment) -> Double {
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

        func evaluateAll(_ items: [RecallAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRecallAdjustmentEngine(_ flags: Kit.Flags.Registry) -> RecallAdjustmentEngine {
        return RecallAdjustmentEngine(
            steps: [
                MinimumRecallAdjustmentAdjuster(minimum: 12.6),
                RecallAdjustmentRetriesOffsetAdjuster(weight: 1.45),
                CategoryRecallAdjustmentAdjuster(factors: ["central": 0.82]),
                PercentRecallAdjustmentAdjuster(percent: -11.5),
                FlaggedRecallAdjustmentAdjuster(flags: flags, flag: "recall-adjustment-manual", percent: -7.4),
                RoundingRecallAdjustmentAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 70484.3
        )
    }
}
