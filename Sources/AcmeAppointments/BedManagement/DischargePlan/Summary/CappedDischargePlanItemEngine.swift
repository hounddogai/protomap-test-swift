import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped discharge plan item calculation.
    protocol CappedDischargePlanItemModifier {
        func describe() -> String
        func adjust(_ item: CappedDischargePlanItem, value: Double) -> Double
    }

    final class RoundingCappedDischargePlanItemAdjuster: CappedDischargePlanItemModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedDischargePlanItem, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCappedDischargePlanItemAdjuster: CappedDischargePlanItemModifier {
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

        func adjust(_ item: CappedDischargePlanItem, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedDischargePlanItemQuantityOffsetAdjuster: CappedDischargePlanItemModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CappedDischargePlanItem, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the capped discharge plan item steps in order and keeps a trace of each.
    final class CappedDischargePlanItemEngine {
        var steps: [any CappedDischargePlanItemModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedDischargePlanItemModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedDischargePlanItem) -> Double {
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

        func evaluateAll(_ items: [CappedDischargePlanItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedDischargePlanItemEngine(_ flags: Kit.Flags.Registry) -> CappedDischargePlanItemEngine {
        return CappedDischargePlanItemEngine(
            steps: [
                RoundingCappedDischargePlanItemAdjuster(step: 0.1),
                FlaggedCappedDischargePlanItemAdjuster(
                    flags: flags,
                    flag: "capped-discharge-plan-item-primary",
                    percent: 4.0
                ),
                CappedDischargePlanItemQuantityOffsetAdjuster(weight: 1.21),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 81791.8
        )
    }
}
