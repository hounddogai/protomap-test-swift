import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization segment calculation.
    protocol AuthorizationSegmentStep {
        func describe() -> String
        func adjust(_ item: AuthorizationSegment, value: Double) -> Double
    }

    final class FlaggedAuthorizationSegmentAdjuster: AuthorizationSegmentStep {
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

        func adjust(_ item: AuthorizationSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleAuthorizationSegmentAdjuster: AuthorizationSegmentStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: AuthorizationSegment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AuthorizationSegmentExpiresAtOffsetAdjuster: AuthorizationSegmentStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: AuthorizationSegment, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class RoundingAuthorizationSegmentAdjuster: AuthorizationSegmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAuthorizationSegmentAdjuster: AuthorizationSegmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAuthorizationSegmentAdjuster: AuthorizationSegmentStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AuthorizationSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the authorization segment steps in order and keeps a trace of each.
    final class AuthorizationSegmentEngine {
        var steps: [any AuthorizationSegmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationSegmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AuthorizationSegment) -> Double {
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

        func evaluateAll(_ items: [AuthorizationSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAuthorizationSegmentEngine(_ flags: Kit.Flags.Registry) -> AuthorizationSegmentEngine {
        return AuthorizationSegmentEngine(
            steps: [
                FlaggedAuthorizationSegmentAdjuster(flags: flags, flag: "authorization-segment-strict", percent: -4.1),
                LocaleAuthorizationSegmentAdjuster(factors: ["east": 0.84, "south": 0.81, "online": 0.84]),
                AuthorizationSegmentExpiresAtOffsetAdjuster(weight: 1.68),
                RoundingAuthorizationSegmentAdjuster(step: 0.05),
                PercentAuthorizationSegmentAdjuster(percent: 17.8),
                TieredAuthorizationSegmentAdjuster(bounds: [4764.0, 4910.0], rates: [0.84, 1.04]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 99316.9
        )
    }
}
