import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the default authorization plan calculation.
    protocol DefaultAuthorizationPlanModifier {
        func describe() -> String
        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double
    }

    final class DefaultAuthorizationPlanWindowDaysOffsetAdjuster: DefaultAuthorizationPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedDefaultAuthorizationPlanAdjuster: DefaultAuthorizationPlanModifier {
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

        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceDefaultAuthorizationPlanAdjuster: DefaultAuthorizationPlanModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDefaultAuthorizationPlanAdjuster: DefaultAuthorizationPlanModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentDefaultAuthorizationPlanAdjuster: DefaultAuthorizationPlanModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDefaultAuthorizationPlanAdjuster: DefaultAuthorizationPlanModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultAuthorizationPlan, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the default authorization plan steps in order and keeps a trace of each.
    final class DefaultAuthorizationPlanEngine {
        var steps: [any DefaultAuthorizationPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAuthorizationPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultAuthorizationPlan) -> Double {
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

        func evaluateAll(_ items: [DefaultAuthorizationPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultAuthorizationPlanEngine(_ flags: Kit.Flags.Registry) -> DefaultAuthorizationPlanEngine {
        return DefaultAuthorizationPlanEngine(
            steps: [
                DefaultAuthorizationPlanWindowDaysOffsetAdjuster(weight: 1.67),
                FlaggedDefaultAuthorizationPlanAdjuster(
                    flags: flags,
                    flag: "default-authorization-plan-manual",
                    percent: -2.7
                ),
                SourceDefaultAuthorizationPlanAdjuster(factors: ["retail": 1.29, "south": 1.3]),
                TieredDefaultAuthorizationPlanAdjuster(
                    bounds: [1671.0, 2191.0, 2236.0, 8035.0],
                    rates: [0.81, 0.87, 1.14, 0.87]
                ),
                PercentDefaultAuthorizationPlanAdjuster(percent: 11.8),
                CapDefaultAuthorizationPlanAdjuster(cap: 31749.0),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 37180.0
        )
    }
}
