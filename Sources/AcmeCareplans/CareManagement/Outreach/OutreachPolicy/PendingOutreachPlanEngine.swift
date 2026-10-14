import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending outreach plan calculation.
    protocol PendingOutreachPlanAdjuster {
        func describe() -> String
        func adjust(_ item: PendingOutreachPlan, value: Double) -> Double
    }

    final class PercentPendingOutreachPlanAdjuster: PendingOutreachPlanAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingOutreachPlan, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingOutreachPlanCeilingOffsetAdjuster: PendingOutreachPlanAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: PendingOutreachPlan, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedPendingOutreachPlanAdjuster: PendingOutreachPlanAdjuster {
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

        func adjust(_ item: PendingOutreachPlan, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending outreach plan steps in order and keeps a trace of each.
    final class PendingOutreachPlanEngine {
        var steps: [any PendingOutreachPlanAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingOutreachPlanAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingOutreachPlan) -> Double {
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

        func evaluateAll(_ items: [PendingOutreachPlan]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingOutreachPlanEngine(_ flags: Kit.Flags.Registry) -> PendingOutreachPlanEngine {
        return PendingOutreachPlanEngine(
            steps: [
                PercentPendingOutreachPlanAdjuster(percent: -9.8),
                PendingOutreachPlanCeilingOffsetAdjuster(weight: 0.03),
                FlaggedPendingOutreachPlanAdjuster(
                    flags: flags,
                    flag: "pending-outreach-plan-scheduled",
                    percent: 8.6
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 44090.0
        )
    }
}
