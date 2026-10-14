import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution estimate calculation.
    protocol SubstitutionEstimateStep {
        func describe() -> String
        func adjust(_ item: SubstitutionEstimate, value: Double) -> Double
    }

    final class FacilitySubstitutionEstimateAdjuster: SubstitutionEstimateStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: SubstitutionEstimate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SubstitutionEstimateAmountOffsetAdjuster: SubstitutionEstimateStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: SubstitutionEstimate, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class MinimumSubstitutionEstimateAdjuster: SubstitutionEstimateStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionEstimate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedSubstitutionEstimateAdjuster: SubstitutionEstimateStep {
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

        func adjust(_ item: SubstitutionEstimate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution estimate steps in order and keeps a trace of each.
    final class SubstitutionEstimateEngine {
        var steps: [any SubstitutionEstimateStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionEstimateStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionEstimate) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [SubstitutionEstimate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionEstimateEngine(_ flags: Kit.Flags.Registry) -> SubstitutionEstimateEngine {
        return SubstitutionEstimateEngine(
            steps: [
                FacilitySubstitutionEstimateAdjuster(factors: ["west": 0.99, "east": 1.07]),
                SubstitutionEstimateAmountOffsetAdjuster(weight: 1.37),
                MinimumSubstitutionEstimateAdjuster(minimum: 27.8),
                FlaggedSubstitutionEstimateAdjuster(
                    flags: flags,
                    flag: "substitution-estimate-weighted",
                    percent: -8.2
                ),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 22532.8
        )
    }
}
