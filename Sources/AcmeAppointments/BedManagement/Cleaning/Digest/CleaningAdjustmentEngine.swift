import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning adjustment calculation.
    protocol CleaningAdjustmentFactor {
        func describe() -> String
        func adjust(_ item: CleaningAdjustment, value: Double) -> Double
    }

    final class RoundingCleaningAdjustmentAdjuster: CleaningAdjustmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredCleaningAdjustmentAdjuster: CleaningAdjustmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCleaningAdjustmentAdjuster: CleaningAdjustmentFactor {
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

        func adjust(_ item: CleaningAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCleaningAdjustmentAdjuster: CleaningAdjustmentFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelCleaningAdjustmentAdjuster: CleaningAdjustmentFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CleaningAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CleaningAdjustmentMarginOffsetAdjuster: CleaningAdjustmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: CleaningAdjustment, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the cleaning adjustment steps in order and keeps a trace of each.
    final class CleaningAdjustmentEngine {
        var steps: [any CleaningAdjustmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningAdjustmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CleaningAdjustment) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CleaningAdjustmentFactor = steps[index]
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

        func evaluateAll(_ items: [CleaningAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCleaningAdjustmentEngine(_ flags: Kit.Flags.Registry) -> CleaningAdjustmentEngine {
        return CleaningAdjustmentEngine(
            steps: [
                RoundingCleaningAdjustmentAdjuster(step: 1.0),
                TieredCleaningAdjustmentAdjuster(bounds: [7178.0, 9588.0], rates: [1.13, 1.08]),
                FlaggedCleaningAdjustmentAdjuster(flags: flags, flag: "cleaning-adjustment-manual", percent: 5.5),
                CapCleaningAdjustmentAdjuster(cap: 33399.0),
                LabelCleaningAdjustmentAdjuster(factors: ["central": 0.84]),
                CleaningAdjustmentMarginOffsetAdjuster(weight: 1.38),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 13255.1
        )
    }
}
