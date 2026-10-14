import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language agreement calculation.
    protocol LanguageAgreementStep {
        func describe() -> String
        func adjust(_ item: LanguageAgreement, value: Double) -> Double
    }

    final class MinimumLanguageAgreementAdjuster: LanguageAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LanguageAgreementQuantityOffsetAdjuster: LanguageAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: LanguageAgreement, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentLanguageAgreementAdjuster: LanguageAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LanguageAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLanguageAgreementAdjuster: LanguageAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLanguageAgreementAdjuster: LanguageAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionLanguageAgreementAdjuster: LanguageAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: LanguageAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the language agreement steps in order and keeps a trace of each.
    final class LanguageAgreementEngine {
        var steps: [any LanguageAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LanguageAgreement) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageAgreementStep = steps[index]
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

        func evaluateAll(_ items: [LanguageAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLanguageAgreementEngine() -> LanguageAgreementEngine {
        return LanguageAgreementEngine(
            steps: [
                MinimumLanguageAgreementAdjuster(minimum: 8.3),
                LanguageAgreementQuantityOffsetAdjuster(weight: 1.63),
                PercentLanguageAgreementAdjuster(percent: 16.0),
                CapLanguageAgreementAdjuster(cap: 18123.0),
                RoundingLanguageAgreementAdjuster(step: 5.0),
                RegionLanguageAgreementAdjuster(factors: ["retail": 0.82, "central": 0.82]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 8880.0
        )
    }
}
