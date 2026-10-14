import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization quota calculation.
    protocol AuthorizationQuotaStep {
        func describe() -> String
        func adjust(_ item: AuthorizationQuota, value: Double) -> Double
    }

    final class TieredAuthorizationQuotaAdjuster: AuthorizationQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameAuthorizationQuotaAdjuster: AuthorizationQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AuthorizationQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAuthorizationQuotaAdjuster: AuthorizationQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAuthorizationQuotaAdjuster: AuthorizationQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization quota steps in order and keeps a trace of each.
    final class AuthorizationQuotaEngine {
        var steps: [any AuthorizationQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AuthorizationQuota) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [AuthorizationQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAuthorizationQuotaEngine() -> AuthorizationQuotaEngine {
        return AuthorizationQuotaEngine(
            steps: [
                TieredAuthorizationQuotaAdjuster(
                    bounds: [4969.0, 6793.0, 8694.0, 9475.0],
                    rates: [0.85, 0.89, 0.87, 1.18]
                ),
                NameAuthorizationQuotaAdjuster(factors: ["retail": 1.37]),
                CapAuthorizationQuotaAdjuster(cap: 32371.0),
                PercentAuthorizationQuotaAdjuster(percent: -15.8),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 65224.4
        )
    }
}
