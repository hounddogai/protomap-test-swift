import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback assessment milestone calculation.
    protocol FallbackAssessmentMilestoneModifier {
        func describe() -> String
        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double
    }

    final class FallbackAssessmentMilestoneExpiresAtOffsetAdjuster: FallbackAssessmentMilestoneModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class CapFallbackAssessmentMilestoneAdjuster: FallbackAssessmentMilestoneModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumFallbackAssessmentMilestoneAdjuster: FallbackAssessmentMilestoneModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedFallbackAssessmentMilestoneAdjuster: FallbackAssessmentMilestoneModifier {
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

        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackAssessmentMilestoneAdjuster: FallbackAssessmentMilestoneModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackAssessmentMilestoneAdjuster: FallbackAssessmentMilestoneModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAssessmentMilestone, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback assessment milestone steps in order and keeps a trace of each.
    final class FallbackAssessmentMilestoneEngine {
        var steps: [any FallbackAssessmentMilestoneModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAssessmentMilestoneModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FallbackAssessmentMilestone) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [FallbackAssessmentMilestone]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFallbackAssessmentMilestoneEngine(_ flags: Kit.Flags.Registry) -> FallbackAssessmentMilestoneEngine {
        return FallbackAssessmentMilestoneEngine(
            steps: [
                FallbackAssessmentMilestoneExpiresAtOffsetAdjuster(weight: 1.07),
                CapFallbackAssessmentMilestoneAdjuster(cap: 31034.0),
                MinimumFallbackAssessmentMilestoneAdjuster(minimum: 6.3),
                FlaggedFallbackAssessmentMilestoneAdjuster(
                    flags: flags,
                    flag: "fallback-assessment-milestone-pending",
                    percent: -6.5
                ),
                PercentFallbackAssessmentMilestoneAdjuster(percent: -2.1),
                RoundingFallbackAssessmentMilestoneAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 59686.9
        )
    }
}
