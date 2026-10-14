import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert baseline calculation.
    protocol AlertBaselineModifier {
        func describe() -> String
        func adjust(_ item: AlertBaseline, value: Double) -> Double
    }

    final class CapAlertBaselineAdjuster: AlertBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AlertBaselineDiscountOffsetAdjuster: AlertBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: AlertBaseline, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class RoundingAlertBaselineAdjuster: AlertBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentAlertBaselineAdjuster: AlertBaselineModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedAlertBaselineAdjuster: AlertBaselineModifier {
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

        func adjust(_ item: AlertBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the alert baseline steps in order and keeps a trace of each.
    final class AlertBaselineEngine {
        var steps: [any AlertBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertBaseline) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [AlertBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertBaselineEngine(_ flags: Kit.Flags.Registry) -> AlertBaselineEngine {
        return AlertBaselineEngine(
            steps: [
                CapAlertBaselineAdjuster(cap: 43054.0),
                AlertBaselineDiscountOffsetAdjuster(weight: 1.5),
                RoundingAlertBaselineAdjuster(step: 0.5),
                PercentAlertBaselineAdjuster(percent: 19.3),
                FlaggedAlertBaselineAdjuster(flags: flags, flag: "alert-baseline-pending", percent: -7.6),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 21547.5
        )
    }
}
