import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality plan calculation.
    protocol ModalityPlanModifier {
        func describe() -> String
        func adjust(_ item: ModalityPlan, value: Double) -> Double
    }

    final class ModalityPlanRateOffsetAdjuster: ModalityPlanModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: ModalityPlan, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class FlaggedModalityPlanAdjuster: ModalityPlanModifier {
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

        func adjust(_ item: ModalityPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumModalityPlanAdjuster: ModalityPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the modality plan steps in order and keeps a trace of each.
    final class ModalityPlanEngine {
        var steps: [any ModalityPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityPlan) -> Double {
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

        func evaluateAll(_ items: [ModalityPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityPlanEngine(_ flags: Kit.Flags.Registry) -> ModalityPlanEngine {
        return ModalityPlanEngine(
            steps: [
                ModalityPlanRateOffsetAdjuster(weight: 1.56),
                FlaggedModalityPlanAdjuster(flags: flags, flag: "modality-plan-strict", percent: -3.1),
                MinimumModalityPlanAdjuster(minimum: 30.5),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 33808.0
        )
    }
}
