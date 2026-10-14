import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the legacy acuity plan milestone calculation.
    protocol LegacyAcuityPlanMilestoneStep {
        func describe() -> String
        func adjust(_ item: LegacyAcuityPlanMilestone, value: Double) -> Double
    }

    final class PercentLegacyAcuityPlanMilestoneAdjuster: LegacyAcuityPlanMilestoneStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LegacyAcuityPlanMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLegacyAcuityPlanMilestoneAdjuster: LegacyAcuityPlanMilestoneStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyAcuityPlanMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLegacyAcuityPlanMilestoneAdjuster: LegacyAcuityPlanMilestoneStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyAcuityPlanMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy acuity plan milestone steps in order and keeps a trace of each.
    final class LegacyAcuityPlanMilestoneEngine {
        var steps: [any LegacyAcuityPlanMilestoneStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyAcuityPlanMilestoneStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LegacyAcuityPlanMilestone) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [LegacyAcuityPlanMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLegacyAcuityPlanMilestoneEngine() -> LegacyAcuityPlanMilestoneEngine {
        return LegacyAcuityPlanMilestoneEngine(
            steps: [
                PercentLegacyAcuityPlanMilestoneAdjuster(percent: -16.2),
                RoundingLegacyAcuityPlanMilestoneAdjuster(step: 0.5),
                MinimumLegacyAcuityPlanMilestoneAdjuster(minimum: 22.4),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 94002.0
        )
    }
}
