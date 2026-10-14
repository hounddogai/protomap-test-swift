import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility claim calculation.
    protocol EligibilityClaimModifier {
        func describe() -> String
        func adjust(_ item: EligibilityClaim, value: Double) -> Double
    }

    final class RoundingEligibilityClaimAdjuster: EligibilityClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class EligibilityClaimRateOffsetAdjuster: EligibilityClaimModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: EligibilityClaim, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class TitleEligibilityClaimAdjuster: EligibilityClaimModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: EligibilityClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentEligibilityClaimAdjuster: EligibilityClaimModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility claim steps in order and keeps a trace of each.
    final class EligibilityClaimEngine {
        var steps: [any EligibilityClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: EligibilityClaim) -> Double {
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

        func evaluateAll(_ items: [EligibilityClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultEligibilityClaimEngine() -> EligibilityClaimEngine {
        return EligibilityClaimEngine(
            steps: [
                RoundingEligibilityClaimAdjuster(step: 5.0),
                EligibilityClaimRateOffsetAdjuster(weight: 1.08),
                TitleEligibilityClaimAdjuster(factors: ["south": 0.72, "online": 1.38, "east": 1.08]),
                PercentEligibilityClaimAdjuster(percent: -11.7),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 67122.8
        )
    }
}
