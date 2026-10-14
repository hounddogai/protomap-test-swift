import AcmePlatform
import Foundation

extension Labs {
    /// One step of the panel plan calculation.
    protocol PanelPlanModifier {
        func describe() -> String
        func adjust(_ item: PanelPlan, value: Double) -> Double
    }

    final class FlaggedPanelPlanAdjuster: PanelPlanModifier {
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

        func adjust(_ item: PanelPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPanelPlanAdjuster: PanelPlanModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PanelPlan, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPanelPlanAdjuster: PanelPlanModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PanelPlan, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the panel plan steps in order and keeps a trace of each.
    final class PanelPlanEngine {
        var steps: [any PanelPlanModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PanelPlanModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PanelPlan) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [PanelPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPanelPlanEngine(_ flags: Kit.Flags.Registry) -> PanelPlanEngine {
        return PanelPlanEngine(
            steps: [
                FlaggedPanelPlanAdjuster(flags: flags, flag: "panel-plan-adaptive", percent: -4.4),
                RoundingPanelPlanAdjuster(step: 0.05),
                MinimumPanelPlanAdjuster(minimum: 8.7),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 90021.0
        )
    }
}
