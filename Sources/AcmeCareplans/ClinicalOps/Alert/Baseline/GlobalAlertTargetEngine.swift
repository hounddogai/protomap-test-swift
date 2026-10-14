import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global alert target calculation.
    protocol GlobalAlertTargetAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalAlertTarget, value: Double) -> Double
    }

    final class PercentGlobalAlertTargetAdjuster: GlobalAlertTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAlertTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalAlertTargetAdjuster: GlobalAlertTargetAdjuster {
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

        func adjust(_ item: GlobalAlertTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalAlertTargetAdjuster: GlobalAlertTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalAlertTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalAlertTargetSequenceOffsetAdjuster: GlobalAlertTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: GlobalAlertTarget, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class TieredGlobalAlertTargetAdjuster: GlobalAlertTargetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalAlertTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global alert target steps in order and keeps a trace of each.
    final class GlobalAlertTargetEngine {
        var steps: [any GlobalAlertTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAlertTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalAlertTarget) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [GlobalAlertTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalAlertTargetEngine(_ flags: Kit.Flags.Registry) -> GlobalAlertTargetEngine {
        return GlobalAlertTargetEngine(
            steps: [
                PercentGlobalAlertTargetAdjuster(percent: 13.4),
                FlaggedGlobalAlertTargetAdjuster(flags: flags, flag: "global-alert-target-rolling", percent: -2.6),
                RoundingGlobalAlertTargetAdjuster(step: 0.5),
                GlobalAlertTargetSequenceOffsetAdjuster(weight: 0.41),
                TieredGlobalAlertTargetAdjuster(
                    bounds: [413.0, 1169.0, 5238.0, 7950.0],
                    rates: [1.19, 1.16, 0.99, 1.16]
                ),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 91982.3
        )
    }
}
