import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization audit calculation.
    protocol AuthorizationAuditStep {
        func describe() -> String
        func adjust(_ item: AuthorizationAudit, value: Double) -> Double
    }

    final class LabelAuthorizationAuditAdjuster: AuthorizationAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AuthorizationAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AuthorizationAuditMinimumOffsetAdjuster: AuthorizationAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: AuthorizationAudit, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class MinimumAuthorizationAuditAdjuster: AuthorizationAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAuthorizationAuditAdjuster: AuthorizationAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAuthorizationAuditAdjuster: AuthorizationAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the authorization audit steps in order and keeps a trace of each.
    final class AuthorizationAuditEngine {
        var steps: [any AuthorizationAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AuthorizationAudit) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationAuditStep = steps[index]
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

        func evaluateAll(_ items: [AuthorizationAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAuthorizationAuditEngine() -> AuthorizationAuditEngine {
        return AuthorizationAuditEngine(
            steps: [
                LabelAuthorizationAuditAdjuster(factors: ["online": 1.21, "east": 1.09]),
                AuthorizationAuditMinimumOffsetAdjuster(weight: 1.13),
                MinimumAuthorizationAuditAdjuster(minimum: 38.6),
                TieredAuthorizationAuditAdjuster(bounds: [3616.0, 8451.0], rates: [1.18, 1.01]),
                CapAuthorizationAuditAdjuster(cap: 44253.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 52029.6
        )
    }
}
