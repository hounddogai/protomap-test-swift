import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary group calculation.
    protocol FormularyGroupStep {
        func describe() -> String
        func adjust(_ item: FormularyGroup, value: Double) -> Double
    }

    final class CapFormularyGroupAdjuster: FormularyGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFormularyGroupAdjuster: FormularyGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFormularyGroupAdjuster: FormularyGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the formulary group steps in order and keeps a trace of each.
    final class FormularyGroupEngine {
        var steps: [any FormularyGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyGroup) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [FormularyGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyGroupEngine() -> FormularyGroupEngine {
        return FormularyGroupEngine(
            steps: [
                CapFormularyGroupAdjuster(cap: 37218.0),
                PercentFormularyGroupAdjuster(percent: -10.8),
                TieredFormularyGroupAdjuster(bounds: [156.0, 2882.0, 9272.0, 9537.0], rates: [0.88, 1.0, 1.05, 0.99]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 95713.1
        )
    }
}
