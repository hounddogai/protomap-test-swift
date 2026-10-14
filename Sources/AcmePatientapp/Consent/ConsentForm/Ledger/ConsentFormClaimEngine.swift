import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form claim calculation.
    protocol ConsentFormClaimStep {
        func describe() -> String
        func adjust(_ item: ConsentFormClaim, value: Double) -> Double
    }

    final class PercentConsentFormClaimAdjuster: ConsentFormClaimStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ConsentFormClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CategoryConsentFormClaimAdjuster: ConsentFormClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: ConsentFormClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredConsentFormClaimAdjuster: ConsentFormClaimStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ConsentFormClaimWindowDaysOffsetAdjuster: ConsentFormClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ConsentFormClaim, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class RoundingConsentFormClaimAdjuster: ConsentFormClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumConsentFormClaimAdjuster: ConsentFormClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the consent form claim steps in order and keeps a trace of each.
    final class ConsentFormClaimEngine {
        var steps: [any ConsentFormClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ConsentFormClaim) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormClaimStep = steps[index]
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

        func evaluateAll(_ items: [ConsentFormClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultConsentFormClaimEngine() -> ConsentFormClaimEngine {
        return ConsentFormClaimEngine(
            steps: [
                PercentConsentFormClaimAdjuster(percent: 15.5),
                CategoryConsentFormClaimAdjuster(factors: ["west": 1.22, "retail": 0.92]),
                TieredConsentFormClaimAdjuster(bounds: [2096.0, 2340.0], rates: [0.94, 0.87]),
                ConsentFormClaimWindowDaysOffsetAdjuster(weight: 1.3),
                RoundingConsentFormClaimAdjuster(step: 0.1),
                MinimumConsentFormClaimAdjuster(minimum: 35.7),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 92098.2
        )
    }
}
