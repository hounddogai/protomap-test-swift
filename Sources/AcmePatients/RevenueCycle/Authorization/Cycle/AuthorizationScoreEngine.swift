import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization score calculation.
    protocol AuthorizationScoreModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationScore, value: Double) -> Double
    }

    final class MinimumAuthorizationScoreAdjuster: AuthorizationScoreModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TitleAuthorizationScoreAdjuster: AuthorizationScoreModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AuthorizationScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAuthorizationScoreAdjuster: AuthorizationScoreModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization score steps in order and keeps a trace of each.
    final class AuthorizationScoreEngine {
        var steps: [any AuthorizationScoreModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationScoreModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationScore) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [AuthorizationScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationScoreEngine() -> AuthorizationScoreEngine {
        return AuthorizationScoreEngine(
            steps: [
                MinimumAuthorizationScoreAdjuster(minimum: 14.7),
                TitleAuthorizationScoreAdjuster(factors: ["retail": 0.96]),
                TieredAuthorizationScoreAdjuster(bounds: [6520.0, 7597.0], rates: [1.04, 0.83]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 66366.5
        )
    }
}
