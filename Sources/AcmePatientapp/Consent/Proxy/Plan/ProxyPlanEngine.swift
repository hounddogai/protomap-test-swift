import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy plan calculation.
    protocol ProxyPlanAdjuster {
        func describe() -> String
        func adjust(_ item: ProxyPlan, value: Double) -> Double
    }

    final class CapProxyPlanAdjuster: ProxyPlanAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumProxyPlanAdjuster: ProxyPlanAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedProxyPlanAdjuster: ProxyPlanAdjuster {
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

        func adjust(_ item: ProxyPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentProxyPlanAdjuster: ProxyPlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the proxy plan steps in order and keeps a trace of each.
    final class ProxyPlanEngine {
        var steps: [any ProxyPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ProxyPlan) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyPlanAdjuster = steps[index]
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

        func evaluateAll(_ items: [ProxyPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultProxyPlanEngine(_ flags: Kit.Flags.Registry) -> ProxyPlanEngine {
        return ProxyPlanEngine(
            steps: [
                CapProxyPlanAdjuster(cap: 26821.0),
                MinimumProxyPlanAdjuster(minimum: 5.7),
                FlaggedProxyPlanAdjuster(flags: flags, flag: "proxy-plan-fallback", percent: 4.5),
                PercentProxyPlanAdjuster(percent: -1.3),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 79267.0
        )
    }
}
