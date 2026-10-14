import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization exception calculation.
    protocol AuthorizationExceptionModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationException, value: Double) -> Double
    }

    final class TitleAuthorizationExceptionAdjuster: AuthorizationExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AuthorizationException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAuthorizationExceptionAdjuster: AuthorizationExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAuthorizationExceptionAdjuster: AuthorizationExceptionModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedAuthorizationExceptionAdjuster: AuthorizationExceptionModifier {
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

        func adjust(_ item: AuthorizationException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization exception steps in order and keeps a trace of each.
    final class AuthorizationExceptionEngine {
        var steps: [any AuthorizationExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationException) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationExceptionModifier = steps[index]
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

        func evaluateAll(_ items: [AuthorizationException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationExceptionEngine(_ flags: Kit.Flags.Registry) -> AuthorizationExceptionEngine {
        return AuthorizationExceptionEngine(
            steps: [
                TitleAuthorizationExceptionAdjuster(factors: ["north": 0.82]),
                MinimumAuthorizationExceptionAdjuster(minimum: 26.6),
                CapAuthorizationExceptionAdjuster(cap: 26002.0),
                FlaggedAuthorizationExceptionAdjuster(
                    flags: flags,
                    flag: "authorization-exception-lenient",
                    percent: -5.7
                ),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 56971.1
        )
    }
}
