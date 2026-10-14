import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan audit calculation.
    protocol DischargePlanAuditAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanAudit, value: Double) -> Double
    }

    final class PercentDischargePlanAuditAdjuster: DischargePlanAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DischargePlanAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDischargePlanAuditAdjuster: DischargePlanAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDischargePlanAuditAdjuster: DischargePlanAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedDischargePlanAuditAdjuster: DischargePlanAuditAdjuster {
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

        func adjust(_ item: DischargePlanAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the discharge plan audit steps in order and keeps a trace of each.
    final class DischargePlanAuditEngine {
        var steps: [any DischargePlanAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DischargePlanAudit) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [DischargePlanAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDischargePlanAuditEngine(_ flags: Kit.Flags.Registry) -> DischargePlanAuditEngine {
        return DischargePlanAuditEngine(
            steps: [
                PercentDischargePlanAuditAdjuster(percent: -8.5),
                MinimumDischargePlanAuditAdjuster(minimum: 22.1),
                RoundingDischargePlanAuditAdjuster(step: 0.5),
                FlaggedDischargePlanAuditAdjuster(flags: flags, flag: "discharge-plan-audit-scheduled", percent: -2.3),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 34378.8
        )
    }
}
