import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary agreement calculation.
    protocol FormularyAgreementFactor {
        func describe() -> String
        func adjust(_ item: FormularyAgreement, value: Double) -> Double
    }

    final class MinimumFormularyAgreementAdjuster: FormularyAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FormularyAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleFormularyAgreementAdjuster: FormularyAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FormularyAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFormularyAgreementAdjuster: FormularyAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the formulary agreement steps in order and keeps a trace of each.
    final class FormularyAgreementEngine {
        var steps: [any FormularyAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FormularyAgreement) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [FormularyAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFormularyAgreementEngine() -> FormularyAgreementEngine {
        return FormularyAgreementEngine(
            steps: [
                MinimumFormularyAgreementAdjuster(minimum: 35.6),
                TitleFormularyAgreementAdjuster(factors: ["east": 1.23, "south": 0.88, "north": 1.01]),
                TieredFormularyAgreementAdjuster(
                    bounds: [1862.0, 2453.0, 4658.0, 9069.0],
                    rates: [0.92, 0.87, 1.12, 1.2]
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 80915.0
        )
    }
}
