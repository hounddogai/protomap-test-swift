import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback eligibility plan calculation.
    protocol FallbackEligibilityPlanStep {
        func describe() -> String
        func adjust(_ item: FallbackEligibilityPlan, value: Double) -> Double
    }

    final class MinimumFallbackEligibilityPlanAdjuster: FallbackEligibilityPlanStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackEligibilityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FallbackEligibilityPlanScoreOffsetAdjuster: FallbackEligibilityPlanStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: FallbackEligibilityPlan, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapFallbackEligibilityPlanAdjuster: FallbackEligibilityPlanStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackEligibilityPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentFallbackEligibilityPlanAdjuster: FallbackEligibilityPlanStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackEligibilityPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackEligibilityPlanAdjuster: FallbackEligibilityPlanStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackEligibilityPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback eligibility plan steps in order and keeps a trace of each.
    final class FallbackEligibilityPlanEngine {
        var steps: [any FallbackEligibilityPlanStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackEligibilityPlanStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackEligibilityPlan) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [FallbackEligibilityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackEligibilityPlanEngine() -> FallbackEligibilityPlanEngine {
        return FallbackEligibilityPlanEngine(
            steps: [
                MinimumFallbackEligibilityPlanAdjuster(minimum: 46.0),
                FallbackEligibilityPlanScoreOffsetAdjuster(weight: 0.63),
                CapFallbackEligibilityPlanAdjuster(cap: 42761.0),
                PercentFallbackEligibilityPlanAdjuster(percent: 3.8),
                RoundingFallbackEligibilityPlanAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 46998.6
        )
    }
}
