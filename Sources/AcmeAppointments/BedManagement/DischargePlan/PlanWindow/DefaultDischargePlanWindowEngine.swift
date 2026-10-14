import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the default discharge plan window calculation.
    protocol DefaultDischargePlanWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double
    }

    final class CategoryDefaultDischargePlanWindowAdjuster: DefaultDischargePlanWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredDefaultDischargePlanWindowAdjuster: DefaultDischargePlanWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDefaultDischargePlanWindowAdjuster: DefaultDischargePlanWindowAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultDischargePlanWindowAdjuster: DefaultDischargePlanWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDefaultDischargePlanWindowAdjuster: DefaultDischargePlanWindowAdjuster {
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

        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultDischargePlanWindowAmountOffsetAdjuster: DefaultDischargePlanWindowAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: DefaultDischargePlanWindow, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the default discharge plan window steps in order and keeps a trace of each.
    final class DefaultDischargePlanWindowEngine {
        var steps: [any DefaultDischargePlanWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDischargePlanWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultDischargePlanWindow) -> Double {
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

        func evaluateAll(_ items: [DefaultDischargePlanWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultDischargePlanWindowEngine(_ flags: Kit.Flags.Registry) -> DefaultDischargePlanWindowEngine {
        return DefaultDischargePlanWindowEngine(
            steps: [
                CategoryDefaultDischargePlanWindowAdjuster(factors: ["west": 0.75]),
                TieredDefaultDischargePlanWindowAdjuster(bounds: [8565.0, 8937.0], rates: [1.16, 1.09]),
                CapDefaultDischargePlanWindowAdjuster(cap: 49459.0),
                PercentDefaultDischargePlanWindowAdjuster(percent: -4.9),
                FlaggedDefaultDischargePlanWindowAdjuster(
                    flags: flags,
                    flag: "default-discharge-plan-window-batched",
                    percent: -8.6
                ),
                DefaultDischargePlanWindowAmountOffsetAdjuster(weight: 1.56),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 41615.5
        )
    }
}
