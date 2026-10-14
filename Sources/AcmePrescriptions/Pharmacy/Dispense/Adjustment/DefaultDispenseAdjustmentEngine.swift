import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the default dispense adjustment calculation.
    protocol DefaultDispenseAdjustmentStep {
        func describe() -> String
        func adjust(_ item: DefaultDispenseAdjustment, value: Double) -> Double
    }

    final class PercentDefaultDispenseAdjustmentAdjuster: DefaultDispenseAdjustmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultDispenseAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedDefaultDispenseAdjustmentAdjuster: DefaultDispenseAdjustmentStep {
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

        func adjust(_ item: DefaultDispenseAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDefaultDispenseAdjustmentAdjuster: DefaultDispenseAdjustmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultDispenseAdjustment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default dispense adjustment steps in order and keeps a trace of each.
    final class DefaultDispenseAdjustmentEngine {
        var steps: [any DefaultDispenseAdjustmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultDispenseAdjustmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultDispenseAdjustment) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [DefaultDispenseAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultDispenseAdjustmentEngine(_ flags: Kit.Flags.Registry) -> DefaultDispenseAdjustmentEngine {
        return DefaultDispenseAdjustmentEngine(
            steps: [
                PercentDefaultDispenseAdjustmentAdjuster(percent: -18.9),
                FlaggedDefaultDispenseAdjustmentAdjuster(
                    flags: flags,
                    flag: "default-dispense-adjustment-default",
                    percent: 4.5
                ),
                MinimumDefaultDispenseAdjustmentAdjuster(minimum: 32.1),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 78116.9
        )
    }
}
