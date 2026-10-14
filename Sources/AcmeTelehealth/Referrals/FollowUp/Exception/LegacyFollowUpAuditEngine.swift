import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the legacy follow up audit calculation.
    protocol LegacyFollowUpAuditAdjuster {
        func describe() -> String
        func adjust(_ item: LegacyFollowUpAudit, value: Double) -> Double
    }

    final class RoundingLegacyFollowUpAuditAdjuster: LegacyFollowUpAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyFollowUpAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyFollowUpAuditAdjuster: LegacyFollowUpAuditAdjuster {
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

        func adjust(_ item: LegacyFollowUpAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LegacyFollowUpAuditMaximumOffsetAdjuster: LegacyFollowUpAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: LegacyFollowUpAudit, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the legacy follow up audit steps in order and keeps a trace of each.
    final class LegacyFollowUpAuditEngine {
        var steps: [any LegacyFollowUpAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyFollowUpAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyFollowUpAudit) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacyFollowUpAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [LegacyFollowUpAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyFollowUpAuditEngine(_ flags: Kit.Flags.Registry) -> LegacyFollowUpAuditEngine {
        return LegacyFollowUpAuditEngine(
            steps: [
                RoundingLegacyFollowUpAuditAdjuster(step: 0.5),
                FlaggedLegacyFollowUpAuditAdjuster(flags: flags, flag: "legacy-follow-up-audit-batched", percent: 0.5),
                LegacyFollowUpAuditMaximumOffsetAdjuster(weight: 1.01),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 73058.6
        )
    }
}
