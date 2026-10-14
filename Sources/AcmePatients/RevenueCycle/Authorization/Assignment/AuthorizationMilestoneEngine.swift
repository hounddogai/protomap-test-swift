import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the authorization milestone calculation.
    protocol AuthorizationMilestoneModifier {
        func describe() -> String
        func adjust(_ item: AuthorizationMilestone, value: Double) -> Double
    }

    final class PercentAuthorizationMilestoneAdjuster: AuthorizationMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AuthorizationMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAuthorizationMilestoneAdjuster: AuthorizationMilestoneModifier {
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

        func adjust(_ item: AuthorizationMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAuthorizationMilestoneAdjuster: AuthorizationMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AuthorizationMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAuthorizationMilestoneAdjuster: AuthorizationMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AuthorizationMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the authorization milestone steps in order and keeps a trace of each.
    final class AuthorizationMilestoneEngine {
        var steps: [any AuthorizationMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AuthorizationMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AuthorizationMilestone) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AuthorizationMilestoneModifier = steps[index]
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

        func evaluateAll(_ items: [AuthorizationMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAuthorizationMilestoneEngine(_ flags: Kit.Flags.Registry) -> AuthorizationMilestoneEngine {
        return AuthorizationMilestoneEngine(
            steps: [
                PercentAuthorizationMilestoneAdjuster(percent: 14.1),
                FlaggedAuthorizationMilestoneAdjuster(
                    flags: flags,
                    flag: "authorization-milestone-manual",
                    percent: 0.3
                ),
                MinimumAuthorizationMilestoneAdjuster(minimum: 18.6),
                CapAuthorizationMilestoneAdjuster(cap: 596.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 65379.8
        )
    }
}
