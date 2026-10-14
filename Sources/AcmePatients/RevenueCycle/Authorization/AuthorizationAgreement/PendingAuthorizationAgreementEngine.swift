import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the pending authorization agreement calculation.
    protocol PendingAuthorizationAgreementFactor {
        func describe() -> String
        func adjust(_ item: PendingAuthorizationAgreement, value: Double) -> Double
    }

    final class FlaggedPendingAuthorizationAgreementAdjuster: PendingAuthorizationAgreementFactor {
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

        func adjust(_ item: PendingAuthorizationAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingAuthorizationAgreementAdjuster: PendingAuthorizationAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingAuthorizationAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class UnitPendingAuthorizationAgreementAdjuster: PendingAuthorizationAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: PendingAuthorizationAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumPendingAuthorizationAgreementAdjuster: PendingAuthorizationAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingAuthorizationAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the pending authorization agreement steps in order and keeps a trace of each.
    final class PendingAuthorizationAgreementEngine {
        var steps: [any PendingAuthorizationAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingAuthorizationAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingAuthorizationAgreement) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingAuthorizationAgreementFactor = steps[index]
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

        func evaluateAll(_ items: [PendingAuthorizationAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingAuthorizationAgreementEngine(_ flags: Kit.Flags.Registry) -> PendingAuthorizationAgreementEngine {
        return PendingAuthorizationAgreementEngine(
            steps: [
                FlaggedPendingAuthorizationAgreementAdjuster(
                    flags: flags,
                    flag: "pending-authorization-agreement-global",
                    percent: -2.8
                ),
                CapPendingAuthorizationAgreementAdjuster(cap: 3020.0),
                UnitPendingAuthorizationAgreementAdjuster(factors: ["south": 0.96]),
                MinimumPendingAuthorizationAgreementAdjuster(minimum: 31.1),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 10315.7
        )
    }
}
