import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary inventory plan calculation.
    protocol PrimaryInventoryPlanModifier {
        func describe() -> String
        func adjust(_ item: PrimaryInventoryPlan, value: Double) -> Double
    }

    final class RoundingPrimaryInventoryPlanAdjuster: PrimaryInventoryPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryInventoryPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPrimaryInventoryPlanAdjuster: PrimaryInventoryPlanModifier {
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

        func adjust(_ item: PrimaryInventoryPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimaryInventoryPlanVersionOffsetAdjuster: PrimaryInventoryPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: PrimaryInventoryPlan, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    /// Runs the primary inventory plan steps in order and keeps a trace of each.
    final class PrimaryInventoryPlanEngine {
        var steps: [any PrimaryInventoryPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryInventoryPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryInventoryPlan) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryInventoryPlanModifier = steps[index]
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

        func evaluateAll(_ items: [PrimaryInventoryPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryInventoryPlanEngine(_ flags: Kit.Flags.Registry) -> PrimaryInventoryPlanEngine {
        return PrimaryInventoryPlanEngine(
            steps: [
                RoundingPrimaryInventoryPlanAdjuster(step: 0.5),
                FlaggedPrimaryInventoryPlanAdjuster(
                    flags: flags,
                    flag: "primary-inventory-plan-global",
                    percent: -4.2
                ),
                PrimaryInventoryPlanVersionOffsetAdjuster(weight: 0.43),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 76948.5
        )
    }
}
