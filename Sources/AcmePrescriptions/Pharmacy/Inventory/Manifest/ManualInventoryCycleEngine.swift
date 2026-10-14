import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual inventory cycle calculation.
    protocol ManualInventoryCycleModifier {
        func describe() -> String
        func adjust(_ item: ManualInventoryCycle, value: Double) -> Double
    }

    final class MinimumManualInventoryCycleAdjuster: ManualInventoryCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualInventoryCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedManualInventoryCycleAdjuster: ManualInventoryCycleModifier {
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

        func adjust(_ item: ManualInventoryCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualInventoryCycleAdjuster: ManualInventoryCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualInventoryCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual inventory cycle steps in order and keeps a trace of each.
    final class ManualInventoryCycleEngine {
        var steps: [any ManualInventoryCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualInventoryCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualInventoryCycle) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualInventoryCycleModifier = steps[index]
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

        func evaluateAll(_ items: [ManualInventoryCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualInventoryCycleEngine(_ flags: Kit.Flags.Registry) -> ManualInventoryCycleEngine {
        return ManualInventoryCycleEngine(
            steps: [
                MinimumManualInventoryCycleAdjuster(minimum: 19.3),
                FlaggedManualInventoryCycleAdjuster(
                    flags: flags,
                    flag: "manual-inventory-cycle-scheduled",
                    percent: -2.5
                ),
                RoundingManualInventoryCycleAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 17795.9
        )
    }
}
