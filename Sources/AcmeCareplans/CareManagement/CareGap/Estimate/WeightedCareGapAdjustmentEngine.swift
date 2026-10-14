import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the weighted care gap adjustment calculation.
    protocol WeightedCareGapAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: WeightedCareGapAdjustment, value: Double) -> Double
    }

    final class RoundingWeightedCareGapAdjustmentAdjuster: WeightedCareGapAdjustmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedCareGapAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WeightedCareGapAdjustmentExpiresAtOffsetAdjuster: WeightedCareGapAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: WeightedCareGapAdjustment, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumWeightedCareGapAdjustmentAdjuster: WeightedCareGapAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedCareGapAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedWeightedCareGapAdjustmentAdjuster: WeightedCareGapAdjustmentModifier {
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

        func adjust(_ item: WeightedCareGapAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted care gap adjustment steps in order and keeps a trace of each.
    final class WeightedCareGapAdjustmentEngine {
        var steps: [any WeightedCareGapAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedCareGapAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedCareGapAdjustment) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [WeightedCareGapAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedCareGapAdjustmentEngine(_ flags: Kit.Flags.Registry) -> WeightedCareGapAdjustmentEngine {
        return WeightedCareGapAdjustmentEngine(
            steps: [
                RoundingWeightedCareGapAdjustmentAdjuster(step: 0.5),
                WeightedCareGapAdjustmentExpiresAtOffsetAdjuster(weight: 1.9),
                MinimumWeightedCareGapAdjustmentAdjuster(minimum: 23.0),
                FlaggedWeightedCareGapAdjustmentAdjuster(
                    flags: flags,
                    flag: "weighted-care-gap-adjustment-primary",
                    percent: -5.1
                ),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 85600.2
        )
    }
}
