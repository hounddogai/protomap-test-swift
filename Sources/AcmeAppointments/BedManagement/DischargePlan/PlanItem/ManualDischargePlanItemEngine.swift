import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the manual discharge plan item calculation.
    protocol ManualDischargePlanItemStep {
        func describe() -> String
        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double
    }

    final class TieredManualDischargePlanItemAdjuster: ManualDischargePlanItemStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedManualDischargePlanItemAdjuster: ManualDischargePlanItemStep {
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

        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualDischargePlanItemVersionOffsetAdjuster: ManualDischargePlanItemStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class PercentManualDischargePlanItemAdjuster: ManualDischargePlanItemStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualDischargePlanItemAdjuster: ManualDischargePlanItemStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleManualDischargePlanItemAdjuster: ManualDischargePlanItemStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ManualDischargePlanItem, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual discharge plan item steps in order and keeps a trace of each.
    final class ManualDischargePlanItemEngine {
        var steps: [any ManualDischargePlanItemStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDischargePlanItemStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualDischargePlanItem) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [ManualDischargePlanItem]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualDischargePlanItemEngine(_ flags: Kit.Flags.Registry) -> ManualDischargePlanItemEngine {
        return ManualDischargePlanItemEngine(
            steps: [
                TieredManualDischargePlanItemAdjuster(bounds: [4976.0, 5978.0, 7037.0], rates: [1.06, 1.18, 0.86]),
                FlaggedManualDischargePlanItemAdjuster(
                    flags: flags,
                    flag: "manual-discharge-plan-item-manual",
                    percent: 3.1
                ),
                ManualDischargePlanItemVersionOffsetAdjuster(weight: 1.38),
                PercentManualDischargePlanItemAdjuster(percent: -21.8),
                RoundingManualDischargePlanItemAdjuster(step: 0.1),
                TitleManualDischargePlanItemAdjuster(factors: ["north": 0.75, "online": 0.9, "central": 1.19]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 6683.0
        )
    }
}
