import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization rollup calculation.
    protocol AuthorizationRollupModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationRollup, value: Double) -> Double
    }

    final class TieredAuthorizationRollupAdjuster: AuthorizationRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAuthorizationRollupAdjuster: AuthorizationRollupModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class AuthorizationRollupVersionOffsetAdjuster: AuthorizationRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: AuthorizationRollup, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class FacilityAuthorizationRollupAdjuster: AuthorizationRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: AuthorizationRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the authorization rollup steps in order and keeps a trace of each.
    final class AuthorizationRollupEngine {
        var steps: [any AuthorizationRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AuthorizationRollup) -> Double {
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

        func evaluateAll(_ items: [AuthorizationRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAuthorizationRollupEngine() -> AuthorizationRollupEngine {
        return AuthorizationRollupEngine(
            steps: [
                TieredAuthorizationRollupAdjuster(bounds: [3267.0, 4830.0], rates: [1.05, 0.87]),
                MinimumAuthorizationRollupAdjuster(minimum: 35.1),
                AuthorizationRollupVersionOffsetAdjuster(weight: 1.85),
                FacilityAuthorizationRollupAdjuster(factors: ["west": 1.06, "east": 1.27, "retail": 1.24]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 75779.6
        )
    }
}
