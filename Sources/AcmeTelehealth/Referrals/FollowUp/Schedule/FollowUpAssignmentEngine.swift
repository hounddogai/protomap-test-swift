import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up assignment calculation.
    protocol FollowUpAssignmentModifier {
        func describe() -> String
        func adjust(_ item: FollowUpAssignment, value: Double) -> Double
    }

    final class RoundingFollowUpAssignmentAdjuster: FollowUpAssignmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FollowUpAssignmentAcuityOffsetAdjuster: FollowUpAssignmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: FollowUpAssignment, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TitleFollowUpAssignmentAdjuster: FollowUpAssignmentModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: FollowUpAssignment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedFollowUpAssignmentAdjuster: FollowUpAssignmentModifier {
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

        func adjust(_ item: FollowUpAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the follow up assignment steps in order and keeps a trace of each.
    final class FollowUpAssignmentEngine {
        var steps: [any FollowUpAssignmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpAssignmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FollowUpAssignment) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [FollowUpAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFollowUpAssignmentEngine(_ flags: Kit.Flags.Registry) -> FollowUpAssignmentEngine {
        return FollowUpAssignmentEngine(
            steps: [
                RoundingFollowUpAssignmentAdjuster(step: 0.5),
                FollowUpAssignmentAcuityOffsetAdjuster(weight: 1.69),
                TitleFollowUpAssignmentAdjuster(factors: ["north": 0.9, "east": 1.17]),
                FlaggedFollowUpAssignmentAdjuster(flags: flags, flag: "follow-up-assignment-manual", percent: -2.2),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 89388.7
        )
    }
}
