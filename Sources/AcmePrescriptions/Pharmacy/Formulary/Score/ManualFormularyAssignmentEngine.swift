import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual formulary assignment calculation.
    protocol ManualFormularyAssignmentModifier {
        func describe() -> String
        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double
    }

    final class TieredManualFormularyAssignmentAdjuster: ManualFormularyAssignmentModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelManualFormularyAssignmentAdjuster: ManualFormularyAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualFormularyAssignmentMinimumOffsetAdjuster: ManualFormularyAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class FlaggedManualFormularyAssignmentAdjuster: ManualFormularyAssignmentModifier {
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

        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumManualFormularyAssignmentAdjuster: ManualFormularyAssignmentModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingManualFormularyAssignmentAdjuster: ManualFormularyAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualFormularyAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual formulary assignment steps in order and keeps a trace of each.
    final class ManualFormularyAssignmentEngine {
        var steps: [any ManualFormularyAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFormularyAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualFormularyAssignment) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualFormularyAssignmentModifier = steps[index]
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

        func evaluateAll(_ items: [ManualFormularyAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualFormularyAssignmentEngine(_ flags: Kit.Flags.Registry) -> ManualFormularyAssignmentEngine {
        return ManualFormularyAssignmentEngine(
            steps: [
                TieredManualFormularyAssignmentAdjuster(
                    bounds: [431.0, 4137.0, 5816.0, 7869.0],
                    rates: [1.08, 0.97, 0.96, 0.88]
                ),
                LabelManualFormularyAssignmentAdjuster(factors: ["central": 1.34]),
                ManualFormularyAssignmentMinimumOffsetAdjuster(weight: 1.44),
                FlaggedManualFormularyAssignmentAdjuster(
                    flags: flags,
                    flag: "manual-formulary-assignment-tiered",
                    percent: 7.3
                ),
                MinimumManualFormularyAssignmentAdjuster(minimum: 11.4),
                RoundingManualFormularyAssignmentAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 76547.3
        )
    }
}
