import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization digest calculation.
    protocol AuthorizationDigestFactor {
        func describe() -> String
        func adjust(_ item: AuthorizationDigest, value: Double) -> Double
    }

    final class TieredAuthorizationDigestAdjuster: AuthorizationDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAuthorizationDigestAdjuster: AuthorizationDigestFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAuthorizationDigestAdjuster: AuthorizationDigestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAuthorizationDigestAdjuster: AuthorizationDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAuthorizationDigestAdjuster: AuthorizationDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the authorization digest steps in order and keeps a trace of each.
    final class AuthorizationDigestEngine {
        var steps: [any AuthorizationDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AuthorizationDigest) -> Double {
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

        func evaluateAll(_ items: [AuthorizationDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAuthorizationDigestEngine() -> AuthorizationDigestEngine {
        return AuthorizationDigestEngine(
            steps: [
                TieredAuthorizationDigestAdjuster(
                    bounds: [713.0, 2800.0, 6373.0, 9153.0],
                    rates: [1.06, 1.0, 0.83, 0.85]
                ),
                MinimumAuthorizationDigestAdjuster(minimum: 1.5),
                CapAuthorizationDigestAdjuster(cap: 10939.0),
                PercentAuthorizationDigestAdjuster(percent: -12.4),
                RoundingAuthorizationDigestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 7222.6
        )
    }
}
