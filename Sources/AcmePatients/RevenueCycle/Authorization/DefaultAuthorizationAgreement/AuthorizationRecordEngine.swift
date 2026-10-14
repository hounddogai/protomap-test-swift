import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization record calculation.
    protocol AuthorizationRecordModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationRecord, value: Double) -> Double
    }

    final class NameAuthorizationRecordAdjuster: AuthorizationRecordModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AuthorizationRecord, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAuthorizationRecordAdjuster: AuthorizationRecordModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationRecord, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AuthorizationRecordDiscountOffsetAdjuster: AuthorizationRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: AuthorizationRecord, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    /// Runs the authorization record steps in order and keeps a trace of each.
    final class AuthorizationRecordEngine {
        var steps: [any AuthorizationRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AuthorizationRecord) -> Double {
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

        func evaluateAll(_ items: [AuthorizationRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAuthorizationRecordEngine() -> AuthorizationRecordEngine {
        return AuthorizationRecordEngine(
            steps: [
                NameAuthorizationRecordAdjuster(factors: ["north": 0.82]),
                RoundingAuthorizationRecordAdjuster(step: 0.05),
                AuthorizationRecordDiscountOffsetAdjuster(weight: 0.15),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 41867.4
        )
    }
}
