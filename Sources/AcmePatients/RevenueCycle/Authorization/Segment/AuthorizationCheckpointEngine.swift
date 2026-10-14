import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization checkpoint calculation.
    protocol AuthorizationCheckpointStep {
        func describe() -> String
        func adjust(_ item: AuthorizationCheckpoint, value: Double) -> Double
    }

    final class PercentAuthorizationCheckpointAdjuster: AuthorizationCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardAuthorizationCheckpointAdjuster: AuthorizationCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: AuthorizationCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAuthorizationCheckpointAdjuster: AuthorizationCheckpointStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the authorization checkpoint steps in order and keeps a trace of each.
    final class AuthorizationCheckpointEngine {
        var steps: [any AuthorizationCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationCheckpoint) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [AuthorizationCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationCheckpointEngine() -> AuthorizationCheckpointEngine {
        return AuthorizationCheckpointEngine(
            steps: [
                PercentAuthorizationCheckpointAdjuster(percent: 18.7),
                WardAuthorizationCheckpointAdjuster(factors: ["north": 0.95, "central": 1.09]),
                CapAuthorizationCheckpointAdjuster(cap: 17936.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 17758.6
        )
    }
}
