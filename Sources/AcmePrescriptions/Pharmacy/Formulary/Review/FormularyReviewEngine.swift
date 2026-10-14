import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary review calculation.
    protocol FormularyReviewModifier {
        func describe() -> String
        func adjust(_ item: FormularyReview, value: Double) -> Double
    }

    final class PercentFormularyReviewAdjuster: FormularyReviewModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularyReview, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFormularyReviewAdjuster: FormularyReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularyReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelFormularyReviewAdjuster: FormularyReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FormularyReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingFormularyReviewAdjuster: FormularyReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FormularyReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the formulary review steps in order and keeps a trace of each.
    final class FormularyReviewEngine {
        var steps: [any FormularyReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularyReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularyReview) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any FormularyReviewModifier = steps[index]
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

        func evaluateAll(_ items: [FormularyReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularyReviewEngine() -> FormularyReviewEngine {
        return FormularyReviewEngine(
            steps: [
                PercentFormularyReviewAdjuster(percent: 19.9),
                CapFormularyReviewAdjuster(cap: 27371.0),
                LabelFormularyReviewAdjuster(factors: ["east": 0.89, "west": 0.89, "online": 1.04]),
                RoundingFormularyReviewAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 78328.6
        )
    }
}
