import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the capped acuity plan assignment calculation.
    protocol CappedAcuityPlanAssignmentStep {
        func describe() -> String
        func adjust(_ item: CappedAcuityPlanAssignment, value: Double) -> Double
    }

    final class RoundingCappedAcuityPlanAssignmentAdjuster: CappedAcuityPlanAssignmentStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedAcuityPlanAssignment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedAcuityPlanAssignmentAdjuster: CappedAcuityPlanAssignmentStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedAcuityPlanAssignment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedAcuityPlanAssignmentAdjuster: CappedAcuityPlanAssignmentStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedAcuityPlanAssignment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCappedAcuityPlanAssignmentAdjuster: CappedAcuityPlanAssignmentStep {
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

        func adjust(_ item: CappedAcuityPlanAssignment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCappedAcuityPlanAssignmentAdjuster: CappedAcuityPlanAssignmentStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedAcuityPlanAssignment, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped acuity plan assignment steps in order and keeps a trace of each.
    final class CappedAcuityPlanAssignmentEngine {
        var steps: [any CappedAcuityPlanAssignmentStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedAcuityPlanAssignmentStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedAcuityPlanAssignment) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [CappedAcuityPlanAssignment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedAcuityPlanAssignmentEngine(_ flags: Kit.Flags.Registry) -> CappedAcuityPlanAssignmentEngine {
        return CappedAcuityPlanAssignmentEngine(
            steps: [
                RoundingCappedAcuityPlanAssignmentAdjuster(step: 5.0),
                PercentCappedAcuityPlanAssignmentAdjuster(percent: 13.9),
                CapCappedAcuityPlanAssignmentAdjuster(cap: 36382.0),
                FlaggedCappedAcuityPlanAssignmentAdjuster(
                    flags: flags,
                    flag: "capped-acuity-plan-assignment-rolling",
                    percent: 8.2
                ),
                MinimumCappedAcuityPlanAssignmentAdjuster(minimum: 47.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 6151.8
        )
    }
}
