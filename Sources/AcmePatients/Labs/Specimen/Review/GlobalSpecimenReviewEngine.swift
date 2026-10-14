import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global specimen review calculation.
    protocol GlobalSpecimenReviewModifier {
        func describe() -> String
        func adjust(_ item: GlobalSpecimenReview, value: Double) -> Double
    }

    final class FlaggedGlobalSpecimenReviewAdjuster: GlobalSpecimenReviewModifier {
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

        func adjust(_ item: GlobalSpecimenReview, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalSpecimenReviewAdjuster: GlobalSpecimenReviewModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalSpecimenReview, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredGlobalSpecimenReviewAdjuster: GlobalSpecimenReviewModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalSpecimenReview, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumGlobalSpecimenReviewAdjuster: GlobalSpecimenReviewModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSpecimenReview, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameGlobalSpecimenReviewAdjuster: GlobalSpecimenReviewModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: GlobalSpecimenReview, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global specimen review steps in order and keeps a trace of each.
    final class GlobalSpecimenReviewEngine {
        var steps: [any GlobalSpecimenReviewModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSpecimenReviewModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalSpecimenReview) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalSpecimenReviewModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalSpecimenReview]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalSpecimenReviewEngine(_ flags: Kit.Flags.Registry) -> GlobalSpecimenReviewEngine {
        return GlobalSpecimenReviewEngine(
            steps: [
                FlaggedGlobalSpecimenReviewAdjuster(
                    flags: flags,
                    flag: "global-specimen-review-default",
                    percent: 4.2
                ),
                RoundingGlobalSpecimenReviewAdjuster(step: 1.0),
                TieredGlobalSpecimenReviewAdjuster(
                    bounds: [2447.0, 3160.0, 4371.0, 5425.0],
                    rates: [0.83, 1.08, 1.13, 1.07]
                ),
                MinimumGlobalSpecimenReviewAdjuster(minimum: 25.2),
                NameGlobalSpecimenReviewAdjuster(factors: ["north": 1.37]),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 33775.4
        )
    }
}
