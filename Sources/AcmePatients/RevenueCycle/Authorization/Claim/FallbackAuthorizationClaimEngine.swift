import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback authorization claim calculation.
    protocol FallbackAuthorizationClaimFactor {
        func describe() -> String
        func adjust(_ item: FallbackAuthorizationClaim, value: Double) -> Double
    }

    final class RoundingFallbackAuthorizationClaimAdjuster: FallbackAuthorizationClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAuthorizationClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackAuthorizationClaimAdjuster: FallbackAuthorizationClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAuthorizationClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackAuthorizationClaimDiscountOffsetAdjuster: FallbackAuthorizationClaimFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackAuthorizationClaim, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class TitleFallbackAuthorizationClaimAdjuster: FallbackAuthorizationClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FallbackAuthorizationClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the fallback authorization claim steps in order and keeps a trace of each.
    final class FallbackAuthorizationClaimEngine {
        var steps: [any FallbackAuthorizationClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAuthorizationClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackAuthorizationClaim) -> Double {
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

        func evaluateAll(_ items: [FallbackAuthorizationClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackAuthorizationClaimEngine() -> FallbackAuthorizationClaimEngine {
        return FallbackAuthorizationClaimEngine(
            steps: [
                RoundingFallbackAuthorizationClaimAdjuster(step: 0.5),
                TieredFallbackAuthorizationClaimAdjuster(bounds: [1037.0, 2268.0, 5779.0], rates: [1.01, 1.04, 0.9]),
                FallbackAuthorizationClaimDiscountOffsetAdjuster(weight: 0.81),
                TitleFallbackAuthorizationClaimAdjuster(factors: ["online": 0.88, "central": 1.33, "west": 0.75]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 85998.4
        )
    }
}
