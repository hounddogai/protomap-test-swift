import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility digest calculation.
    protocol EligibilityDigestModifier {
        func describe() -> String
        func adjust(_ item: EligibilityDigest, value: Double) -> Double
    }

    final class EligibilityDigestStartsAtOffsetAdjuster: EligibilityDigestModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: EligibilityDigest, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentEligibilityDigestAdjuster: EligibilityDigestModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: EligibilityDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumEligibilityDigestAdjuster: EligibilityDigestModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelEligibilityDigestAdjuster: EligibilityDigestModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: EligibilityDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility digest steps in order and keeps a trace of each.
    final class EligibilityDigestEngine {
        var steps: [any EligibilityDigestModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityDigestModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: EligibilityDigest) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any EligibilityDigestModifier = steps[index]
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

        func evaluateAll(_ items: [EligibilityDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultEligibilityDigestEngine() -> EligibilityDigestEngine {
        return EligibilityDigestEngine(
            steps: [
                EligibilityDigestStartsAtOffsetAdjuster(weight: 0.68),
                PercentEligibilityDigestAdjuster(percent: -11.4),
                MinimumEligibilityDigestAdjuster(minimum: 38.0),
                LabelEligibilityDigestAdjuster(factors: ["retail": 1.36]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 40628.8
        )
    }
}
