import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary bundle calculation.
    protocol FormularyBundleFactor {
        func describe() -> String
        func adjust(_ item: FormularyBundle, value: Double) -> Double
    }

    final class MinimumFormularyBundleAdjuster: FormularyBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FormularyBundleGraceDaysOffsetAdjuster: FormularyBundleFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: FormularyBundle, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class CapFormularyBundleAdjuster: FormularyBundleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFormularyBundleAdjuster: FormularyBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFormularyBundleAdjuster: FormularyBundleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFormularyBundleAdjuster: FormularyBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the formulary bundle steps in order and keeps a trace of each.
    final class FormularyBundleEngine {
        var steps: [any FormularyBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyBundle) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [FormularyBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyBundleEngine() -> FormularyBundleEngine {
        return FormularyBundleEngine(
            steps: [
                MinimumFormularyBundleAdjuster(minimum: 30.0),
                FormularyBundleGraceDaysOffsetAdjuster(weight: 0.11),
                CapFormularyBundleAdjuster(cap: 5321.0),
                RoundingFormularyBundleAdjuster(step: 0.25),
                PercentFormularyBundleAdjuster(percent: 7.2),
                TieredFormularyBundleAdjuster(bounds: [2524.0, 6441.0, 9828.0], rates: [1.15, 0.83, 0.85]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 56014.3
        )
    }
}
