import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient authorization claim calculation.
    protocol LenientAuthorizationClaimAdjuster {
        func describe() -> String
        func adjust(_ item: LenientAuthorizationClaim, value: Double) -> Double
    }

    final class LenientAuthorizationClaimEndsAtOffsetAdjuster: LenientAuthorizationClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: LenientAuthorizationClaim, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class FlaggedLenientAuthorizationClaimAdjuster: LenientAuthorizationClaimAdjuster {
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

        func adjust(_ item: LenientAuthorizationClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientAuthorizationClaimAdjuster: LenientAuthorizationClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientAuthorizationClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SourceLenientAuthorizationClaimAdjuster: LenientAuthorizationClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LenientAuthorizationClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient authorization claim steps in order and keeps a trace of each.
    final class LenientAuthorizationClaimEngine {
        var steps: [any LenientAuthorizationClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAuthorizationClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientAuthorizationClaim) -> Double {
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

        func evaluateAll(_ items: [LenientAuthorizationClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientAuthorizationClaimEngine(_ flags: Kit.Flags.Registry) -> LenientAuthorizationClaimEngine {
        return LenientAuthorizationClaimEngine(
            steps: [
                LenientAuthorizationClaimEndsAtOffsetAdjuster(weight: 1.6),
                FlaggedLenientAuthorizationClaimAdjuster(
                    flags: flags,
                    flag: "lenient-authorization-claim-default",
                    percent: 4.6
                ),
                MinimumLenientAuthorizationClaimAdjuster(minimum: 1.6),
                SourceLenientAuthorizationClaimAdjuster(factors: ["east": 0.8]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 96268.4
        )
    }
}
