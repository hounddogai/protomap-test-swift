import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization assignment calculation.
    protocol AuthorizationAssignmentAdjuster {
        func describe() -> String
        func adjust(_ item: AuthorizationAssignment, value: Double) -> Double
    }

    final class CapAuthorizationAssignmentAdjuster: AuthorizationAssignmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityAuthorizationAssignmentAdjuster: AuthorizationAssignmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: AuthorizationAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAuthorizationAssignmentAdjuster: AuthorizationAssignmentAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredAuthorizationAssignmentAdjuster: AuthorizationAssignmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationAssignment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization assignment steps in order and keeps a trace of each.
    final class AuthorizationAssignmentEngine {
        var steps: [any AuthorizationAssignmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationAssignmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AuthorizationAssignment) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AuthorizationAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAuthorizationAssignmentEngine() -> AuthorizationAssignmentEngine {
        return AuthorizationAssignmentEngine(
            steps: [
                CapAuthorizationAssignmentAdjuster(cap: 27971.0),
                FacilityAuthorizationAssignmentAdjuster(factors: ["west": 0.78]),
                MinimumAuthorizationAssignmentAdjuster(minimum: 39.2),
                TieredAuthorizationAssignmentAdjuster(bounds: [5907.0, 9094.0], rates: [1.04, 1.1]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 37904.4
        )
    }
}
