import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary draft calculation.
    protocol FormularyDraftAdjuster {
        func describe() -> String
        func adjust(_ item: FormularyDraft, value: Double) -> Double
    }

    final class TieredFormularyDraftAdjuster: FormularyDraftAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularyDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFormularyDraftAdjuster: FormularyDraftAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFormularyDraftAdjuster: FormularyDraftAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FormularyDraftAcuityOffsetAdjuster: FormularyDraftAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: FormularyDraft, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the formulary draft steps in order and keeps a trace of each.
    final class FormularyDraftEngine {
        var steps: [any FormularyDraftAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyDraftAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FormularyDraft) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyDraftAdjuster = steps[index]
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

        func evaluateAll(_ items: [FormularyDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFormularyDraftEngine() -> FormularyDraftEngine {
        return FormularyDraftEngine(
            steps: [
                TieredFormularyDraftAdjuster(
                    bounds: [2864.0, 3892.0, 7986.0, 9198.0],
                    rates: [1.16, 1.18, 0.82, 1.17]
                ),
                PercentFormularyDraftAdjuster(percent: 17.2),
                RoundingFormularyDraftAdjuster(step: 1.0),
                FormularyDraftAcuityOffsetAdjuster(weight: 1.77),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 33869.0
        )
    }
}
