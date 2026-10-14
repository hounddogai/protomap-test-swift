import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization metric calculation.
    protocol AuthorizationMetricFactor {
        func describe() -> String
        func adjust(_ item: AuthorizationMetric, value: Double) -> Double
    }

    final class FlaggedAuthorizationMetricAdjuster: AuthorizationMetricFactor {
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

        func adjust(_ item: AuthorizationMetric, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentAuthorizationMetricAdjuster: AuthorizationMetricFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAuthorizationMetricAdjuster: AuthorizationMetricFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationMetric, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryAuthorizationMetricAdjuster: AuthorizationMetricFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: AuthorizationMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAuthorizationMetricAdjuster: AuthorizationMetricFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationMetric, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAuthorizationMetricAdjuster: AuthorizationMetricFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationMetric, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization metric steps in order and keeps a trace of each.
    final class AuthorizationMetricEngine {
        var steps: [any AuthorizationMetricFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationMetricFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AuthorizationMetric) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [AuthorizationMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAuthorizationMetricEngine(_ flags: Kit.Flags.Registry) -> AuthorizationMetricEngine {
        return AuthorizationMetricEngine(
            steps: [
                FlaggedAuthorizationMetricAdjuster(flags: flags, flag: "authorization-metric-pending", percent: 7.8),
                PercentAuthorizationMetricAdjuster(percent: -20.7),
                MinimumAuthorizationMetricAdjuster(minimum: 12.5),
                CategoryAuthorizationMetricAdjuster(factors: ["west": 0.96]),
                CapAuthorizationMetricAdjuster(cap: 21046.0),
                TieredAuthorizationMetricAdjuster(bounds: [1682.0, 5518.0], rates: [0.96, 1.12]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 22506.3
        )
    }
}
