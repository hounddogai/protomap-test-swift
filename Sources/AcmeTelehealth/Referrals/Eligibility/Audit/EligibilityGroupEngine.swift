import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility group calculation.
    protocol EligibilityGroupFactor {
        func describe() -> String
        func adjust(_ item: EligibilityGroup, value: Double) -> Double
    }

    final class TieredEligibilityGroupAdjuster: EligibilityGroupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingEligibilityGroupAdjuster: EligibilityGroupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: EligibilityGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumEligibilityGroupAdjuster: EligibilityGroupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitEligibilityGroupAdjuster: EligibilityGroupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: EligibilityGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the eligibility group steps in order and keeps a trace of each.
    final class EligibilityGroupEngine {
        var steps: [any EligibilityGroupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityGroupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: EligibilityGroup) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [EligibilityGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultEligibilityGroupEngine() -> EligibilityGroupEngine {
        return EligibilityGroupEngine(
            steps: [
                TieredEligibilityGroupAdjuster(bounds: [1243.0, 1780.0, 8541.0], rates: [1.17, 1.11, 1.09]),
                RoundingEligibilityGroupAdjuster(step: 5.0),
                MinimumEligibilityGroupAdjuster(minimum: 47.1),
                UnitEligibilityGroupAdjuster(factors: ["retail": 1.05]),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 98241.0
        )
    }
}
