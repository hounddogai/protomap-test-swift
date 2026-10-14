import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary metric calculation.
    protocol FormularyMetricModifier {
        func describe() -> String
        func adjust(_ item: FormularyMetric, value: Double) -> Double
    }

    final class CapFormularyMetricAdjuster: FormularyMetricModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFormularyMetricAdjuster: FormularyMetricModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyMetric, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFormularyMetricAdjuster: FormularyMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleFormularyMetricAdjuster: FormularyMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FormularyMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFormularyMetricAdjuster: FormularyMetricModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFormularyMetricAdjuster: FormularyMetricModifier {
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

        func adjust(_ item: FormularyMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the formulary metric steps in order and keeps a trace of each.
    final class FormularyMetricEngine {
        var steps: [any FormularyMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyMetric) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [FormularyMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyMetricEngine(_ flags: Kit.Flags.Registry) -> FormularyMetricEngine {
        return FormularyMetricEngine(
            steps: [
                CapFormularyMetricAdjuster(cap: 3314.0),
                RoundingFormularyMetricAdjuster(step: 5.0),
                PercentFormularyMetricAdjuster(percent: 7.7),
                TitleFormularyMetricAdjuster(factors: ["north": 1.18, "east": 0.87]),
                TieredFormularyMetricAdjuster(bounds: [2154.0, 2583.0, 8693.0], rates: [0.9, 0.94, 1.16]),
                FlaggedFormularyMetricAdjuster(flags: flags, flag: "formulary-metric-adaptive", percent: 3.5),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 51334.5
        )
    }
}
