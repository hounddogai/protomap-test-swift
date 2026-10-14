import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary discharge plan adjustment calculation.
    protocol PrimaryDischargePlanAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: PrimaryDischargePlanAdjustment, value: Double) -> Double
    }

    final class CapPrimaryDischargePlanAdjustmentAdjuster: PrimaryDischargePlanAdjustmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryDischargePlanAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumPrimaryDischargePlanAdjustmentAdjuster: PrimaryDischargePlanAdjustmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PrimaryDischargePlanAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PrimaryDischargePlanAdjustmentDurationMinutesOffsetAdjuster: PrimaryDischargePlanAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: PrimaryDischargePlanAdjustment, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    /// Runs the primary discharge plan adjustment steps in order and keeps a trace of each.
    final class PrimaryDischargePlanAdjustmentEngine {
        var steps: [any PrimaryDischargePlanAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryDischargePlanAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PrimaryDischargePlanAdjustment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryDischargePlanAdjustmentModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryDischargePlanAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPrimaryDischargePlanAdjustmentEngine() -> PrimaryDischargePlanAdjustmentEngine {
        return PrimaryDischargePlanAdjustmentEngine(
            steps: [
                CapPrimaryDischargePlanAdjustmentAdjuster(cap: 13334.0),
                MinimumPrimaryDischargePlanAdjustmentAdjuster(minimum: 36.7),
                PrimaryDischargePlanAdjustmentDurationMinutesOffsetAdjuster(weight: 1.62),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 54588.8
        )
    }
}
