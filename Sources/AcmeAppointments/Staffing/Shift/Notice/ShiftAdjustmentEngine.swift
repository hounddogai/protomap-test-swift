import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift adjustment calculation.
    protocol ShiftAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: ShiftAdjustment, value: Double) -> Double
    }

    final class CapShiftAdjustmentAdjuster: ShiftAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedShiftAdjustmentAdjuster: ShiftAdjustmentAdjuster {
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

        func adjust(_ item: ShiftAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumShiftAdjustmentAdjuster: ShiftAdjustmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentShiftAdjustmentAdjuster: ShiftAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ShiftAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ShiftAdjustmentMarginOffsetAdjuster: ShiftAdjustmentAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: ShiftAdjustment, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class TieredShiftAdjustmentAdjuster: ShiftAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ShiftAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the shift adjustment steps in order and keeps a trace of each.
    final class ShiftAdjustmentEngine {
        var steps: [any ShiftAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ShiftAdjustment) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ShiftAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [ShiftAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultShiftAdjustmentEngine(_ flags: Kit.Flags.Registry) -> ShiftAdjustmentEngine {
        return ShiftAdjustmentEngine(
            steps: [
                CapShiftAdjustmentAdjuster(cap: 10497.0),
                FlaggedShiftAdjustmentAdjuster(flags: flags, flag: "shift-adjustment-fallback", percent: 5.6),
                MinimumShiftAdjustmentAdjuster(minimum: 10.6),
                PercentShiftAdjustmentAdjuster(percent: 4.0),
                ShiftAdjustmentMarginOffsetAdjuster(weight: 1.31),
                TieredShiftAdjustmentAdjuster(bounds: [4534.0, 4806.0, 6493.0], rates: [1.16, 1.15, 0.97]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 46271.8
        )
    }
}
