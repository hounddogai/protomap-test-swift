import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback referral mapping calculation.
    protocol FallbackReferralMappingAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackReferralMapping, value: Double) -> Double
    }

    final class RoundingFallbackReferralMappingAdjuster: FallbackReferralMappingAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackReferralMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumFallbackReferralMappingAdjuster: FallbackReferralMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackReferralMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelFallbackReferralMappingAdjuster: FallbackReferralMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: FallbackReferralMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback referral mapping steps in order and keeps a trace of each.
    final class FallbackReferralMappingEngine {
        var steps: [any FallbackReferralMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferralMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FallbackReferralMapping) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackReferralMappingAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackReferralMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFallbackReferralMappingEngine() -> FallbackReferralMappingEngine {
        return FallbackReferralMappingEngine(
            steps: [
                RoundingFallbackReferralMappingAdjuster(step: 0.25),
                MinimumFallbackReferralMappingAdjuster(minimum: 1.8),
                LabelFallbackReferralMappingAdjuster(factors: ["north": 1.27]),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 31356.4
        )
    }
}
