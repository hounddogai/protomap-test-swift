import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution quota calculation.
    protocol SubstitutionQuotaStep {
        func describe() -> String
        func adjust(_ item: SubstitutionQuota, value: Double) -> Double
    }

    final class LabelSubstitutionQuotaAdjuster: SubstitutionQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SubstitutionQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SubstitutionQuotaExpiresAtOffsetAdjuster: SubstitutionQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: SubstitutionQuota, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumSubstitutionQuotaAdjuster: SubstitutionQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SubstitutionQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the substitution quota steps in order and keeps a trace of each.
    final class SubstitutionQuotaEngine {
        var steps: [any SubstitutionQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SubstitutionQuota) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any SubstitutionQuotaStep = steps[index]
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

        func evaluateAll(_ items: [SubstitutionQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSubstitutionQuotaEngine() -> SubstitutionQuotaEngine {
        return SubstitutionQuotaEngine(
            steps: [
                LabelSubstitutionQuotaAdjuster(factors: ["central": 0.89]),
                SubstitutionQuotaExpiresAtOffsetAdjuster(weight: 0.37),
                MinimumSubstitutionQuotaAdjuster(minimum: 21.5),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 33848.2
        )
    }
}
