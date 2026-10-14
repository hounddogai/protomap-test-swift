import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert target calculation.
    protocol AlertTargetModifier {
        func describe() -> String
        func adjust(_ item: AlertTarget, value: Double) -> Double
    }

    final class RoundingAlertTargetAdjuster: AlertTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAlertTargetAdjuster: AlertTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedAlertTargetAdjuster: AlertTargetModifier {
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

        func adjust(_ item: AlertTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the alert target steps in order and keeps a trace of each.
    final class AlertTargetEngine {
        var steps: [any AlertTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertTarget) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AlertTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertTargetEngine(_ flags: Kit.Flags.Registry) -> AlertTargetEngine {
        return AlertTargetEngine(
            steps: [
                RoundingAlertTargetAdjuster(step: 0.05),
                TieredAlertTargetAdjuster(bounds: [3128.0, 8004.0, 8581.0], rates: [0.82, 0.85, 0.81]),
                FlaggedAlertTargetAdjuster(flags: flags, flag: "alert-target-adaptive", percent: -2.4),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 97695.3
        )
    }
}
