import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal eligibility quota calculation.
    protocol SeasonalEligibilityQuotaStep {
        func describe() -> String
        func adjust(_ item: SeasonalEligibilityQuota, value: Double) -> Double
    }

    final class MinimumSeasonalEligibilityQuotaAdjuster: SeasonalEligibilityQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalEligibilityQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentSeasonalEligibilityQuotaAdjuster: SeasonalEligibilityQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalEligibilityQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingSeasonalEligibilityQuotaAdjuster: SeasonalEligibilityQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SeasonalEligibilityQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the seasonal eligibility quota steps in order and keeps a trace of each.
    final class SeasonalEligibilityQuotaEngine {
        var steps: [any SeasonalEligibilityQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalEligibilityQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalEligibilityQuota) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [SeasonalEligibilityQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalEligibilityQuotaEngine() -> SeasonalEligibilityQuotaEngine {
        return SeasonalEligibilityQuotaEngine(
            steps: [
                MinimumSeasonalEligibilityQuotaAdjuster(minimum: 34.7),
                PercentSeasonalEligibilityQuotaAdjuster(percent: -0.9),
                RoundingSeasonalEligibilityQuotaAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 24115.8
        )
    }
}
