import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization entry calculation.
    protocol AuthorizationEntryAdjuster {
        func describe() -> String
        func adjust(_ item: AuthorizationEntry, value: Double) -> Double
    }

    final class FacilityAuthorizationEntryAdjuster: AuthorizationEntryAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: AuthorizationEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAuthorizationEntryAdjuster: AuthorizationEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AuthorizationEntryThresholdOffsetAdjuster: AuthorizationEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: AuthorizationEntry, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class PercentAuthorizationEntryAdjuster: AuthorizationEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAuthorizationEntryAdjuster: AuthorizationEntryAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAuthorizationEntryAdjuster: AuthorizationEntryAdjuster {
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

        func adjust(_ item: AuthorizationEntry, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the authorization entry steps in order and keeps a trace of each.
    final class AuthorizationEntryEngine {
        var steps: [any AuthorizationEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AuthorizationEntry) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [AuthorizationEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAuthorizationEntryEngine(_ flags: Kit.Flags.Registry) -> AuthorizationEntryEngine {
        return AuthorizationEntryEngine(
            steps: [
                FacilityAuthorizationEntryAdjuster(factors: ["west": 1.1, "central": 0.83]),
                CapAuthorizationEntryAdjuster(cap: 25795.0),
                AuthorizationEntryThresholdOffsetAdjuster(weight: 0.38),
                PercentAuthorizationEntryAdjuster(percent: -6.6),
                MinimumAuthorizationEntryAdjuster(minimum: 10.8),
                FlaggedAuthorizationEntryAdjuster(flags: flags, flag: "authorization-entry-strict", percent: 4.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 70056.9
        )
    }
}
