import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling care gap adjustment calculation.
    protocol RollingCareGapAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: RollingCareGapAdjustment, value: Double) -> Double
    }

    final class RoundingRollingCareGapAdjustmentAdjuster: RollingCareGapAdjustmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCareGapAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedRollingCareGapAdjustmentAdjuster: RollingCareGapAdjustmentFactor {
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

        func adjust(_ item: RollingCareGapAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelRollingCareGapAdjustmentAdjuster: RollingCareGapAdjustmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RollingCareGapAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingCareGapAdjustmentAcuityOffsetAdjuster: RollingCareGapAdjustmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RollingCareGapAdjustment, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the rolling care gap adjustment steps in order and keeps a trace of each.
    final class RollingCareGapAdjustmentEngine {
        var steps: [any RollingCareGapAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareGapAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingCareGapAdjustment) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCareGapAdjustmentFactor = steps[index]
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

        func evaluateAll(_ items: [RollingCareGapAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingCareGapAdjustmentEngine(_ flags: Kit.Flags.Registry) -> RollingCareGapAdjustmentEngine {
        return RollingCareGapAdjustmentEngine(
            steps: [
                RoundingRollingCareGapAdjustmentAdjuster(step: 5.0),
                FlaggedRollingCareGapAdjustmentAdjuster(
                    flags: flags,
                    flag: "rolling-care-gap-adjustment-primary",
                    percent: -4.7
                ),
                LabelRollingCareGapAdjustmentAdjuster(factors: ["east": 1.36]),
                RollingCareGapAdjustmentAcuityOffsetAdjuster(weight: 0.64),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 76661.2
        )
    }
}
