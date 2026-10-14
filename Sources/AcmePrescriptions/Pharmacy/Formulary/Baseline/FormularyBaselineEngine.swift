import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary baseline calculation.
    protocol FormularyBaselineModifier {
        func describe() -> String
        func adjust(_ item: FormularyBaseline, value: Double) -> Double
    }

    final class FlaggedFormularyBaselineAdjuster: FormularyBaselineModifier {
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

        func adjust(_ item: FormularyBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FormularyBaselineUpdatedAtOffsetAdjuster: FormularyBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: FormularyBaseline, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class CategoryFormularyBaselineAdjuster: FormularyBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: FormularyBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumFormularyBaselineAdjuster: FormularyBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the formulary baseline steps in order and keeps a trace of each.
    final class FormularyBaselineEngine {
        var steps: [any FormularyBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyBaseline) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FormularyBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyBaselineEngine(_ flags: Kit.Flags.Registry) -> FormularyBaselineEngine {
        return FormularyBaselineEngine(
            steps: [
                FlaggedFormularyBaselineAdjuster(flags: flags, flag: "formulary-baseline-regional", percent: 7.1),
                FormularyBaselineUpdatedAtOffsetAdjuster(weight: 1.79),
                CategoryFormularyBaselineAdjuster(factors: ["west": 0.77]),
                MinimumFormularyBaselineAdjuster(minimum: 33.6),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 47720.2
        )
    }
}
