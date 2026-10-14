import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization ledger calculation.
    protocol AuthorizationLedgerModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationLedger, value: Double) -> Double
    }

    final class TieredAuthorizationLedgerAdjuster: AuthorizationLedgerModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAuthorizationLedgerAdjuster: AuthorizationLedgerModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAuthorizationLedgerAdjuster: AuthorizationLedgerModifier {
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

        func adjust(_ item: AuthorizationLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization ledger steps in order and keeps a trace of each.
    final class AuthorizationLedgerEngine {
        var steps: [any AuthorizationLedgerModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationLedgerModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AuthorizationLedger) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [AuthorizationLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAuthorizationLedgerEngine(_ flags: Kit.Flags.Registry) -> AuthorizationLedgerEngine {
        return AuthorizationLedgerEngine(
            steps: [
                TieredAuthorizationLedgerAdjuster(bounds: [2707.0, 5373.0, 5509.0], rates: [1.12, 0.93, 0.87]),
                MinimumAuthorizationLedgerAdjuster(minimum: 10.1),
                FlaggedAuthorizationLedgerAdjuster(flags: flags, flag: "authorization-ledger-regional", percent: 9.7),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 37652.8
        )
    }
}
