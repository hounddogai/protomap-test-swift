import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization mapping calculation.
    protocol AuthorizationMappingModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationMapping, value: Double) -> Double
    }

    final class FlaggedAuthorizationMappingAdjuster: AuthorizationMappingModifier {
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

        func adjust(_ item: AuthorizationMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AuthorizationMappingStartsAtOffsetAdjuster: AuthorizationMappingModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: AuthorizationMapping, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentAuthorizationMappingAdjuster: AuthorizationMappingModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationMapping, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAuthorizationMappingAdjuster: AuthorizationMappingModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionAuthorizationMappingAdjuster: AuthorizationMappingModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: AuthorizationMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingAuthorizationMappingAdjuster: AuthorizationMappingModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AuthorizationMapping, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the authorization mapping steps in order and keeps a trace of each.
    final class AuthorizationMappingEngine {
        var steps: [any AuthorizationMappingModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationMappingModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AuthorizationMapping) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationMappingModifier = steps[index]
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

        func evaluateAll(_ items: [AuthorizationMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAuthorizationMappingEngine(_ flags: Kit.Flags.Registry) -> AuthorizationMappingEngine {
        return AuthorizationMappingEngine(
            steps: [
                FlaggedAuthorizationMappingAdjuster(flags: flags, flag: "authorization-mapping-pending", percent: 0.2),
                AuthorizationMappingStartsAtOffsetAdjuster(weight: 0.98),
                PercentAuthorizationMappingAdjuster(percent: 23.9),
                CapAuthorizationMappingAdjuster(cap: 35447.0),
                RegionAuthorizationMappingAdjuster(factors: ["central": 1.15, "south": 0.81, "retail": 1.17]),
                RoundingAuthorizationMappingAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 28086.8
        )
    }
}
