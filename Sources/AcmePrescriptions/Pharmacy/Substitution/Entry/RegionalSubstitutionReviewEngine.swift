import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional substitution review calculation.
    protocol RegionalSubstitutionReviewModifier {
        func describe() -> String
        func adjust(_ item: RegionalSubstitutionReview, value: Double) -> Double
    }

    final class FlaggedRegionalSubstitutionReviewAdjuster: RegionalSubstitutionReviewModifier {
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

        func adjust(_ item: RegionalSubstitutionReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalSubstitutionReviewAdjuster: RegionalSubstitutionReviewModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalSubstitutionReview, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionalSubstitutionReviewRateOffsetAdjuster: RegionalSubstitutionReviewModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RegionalSubstitutionReview, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CountryRegionalSubstitutionReviewAdjuster: RegionalSubstitutionReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RegionalSubstitutionReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional substitution review steps in order and keeps a trace of each.
    final class RegionalSubstitutionReviewEngine {
        var steps: [any RegionalSubstitutionReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalSubstitutionReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalSubstitutionReview) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [RegionalSubstitutionReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalSubstitutionReviewEngine(_ flags: Kit.Flags.Registry) -> RegionalSubstitutionReviewEngine {
        return RegionalSubstitutionReviewEngine(
            steps: [
                FlaggedRegionalSubstitutionReviewAdjuster(
                    flags: flags,
                    flag: "regional-substitution-review-pending",
                    percent: -3.2
                ),
                CapRegionalSubstitutionReviewAdjuster(cap: 43534.0),
                RegionalSubstitutionReviewRateOffsetAdjuster(weight: 0.62),
                CountryRegionalSubstitutionReviewAdjuster(factors: ["north": 1.34, "west": 0.98, "central": 1.03]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 89259.2
        )
    }
}
