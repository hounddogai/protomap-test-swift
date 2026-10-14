import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the overtime audit calculation.
    protocol OvertimeAuditModifier {
        func describe() -> String
        func adjust(_ item: OvertimeAudit, value: Double) -> Double
    }

    final class OvertimeAuditCopayOffsetAdjuster: OvertimeAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: OvertimeAudit, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class CapOvertimeAuditAdjuster: OvertimeAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OvertimeAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedOvertimeAuditAdjuster: OvertimeAuditModifier {
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

        func adjust(_ item: OvertimeAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingOvertimeAuditAdjuster: OvertimeAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OvertimeAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumOvertimeAuditAdjuster: OvertimeAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: OvertimeAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityOvertimeAuditAdjuster: OvertimeAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: OvertimeAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the overtime audit steps in order and keeps a trace of each.
    final class OvertimeAuditEngine {
        var steps: [any OvertimeAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OvertimeAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: OvertimeAudit) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OvertimeAuditModifier = steps[index]
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

        func evaluateAll(_ items: [OvertimeAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultOvertimeAuditEngine(_ flags: Kit.Flags.Registry) -> OvertimeAuditEngine {
        return OvertimeAuditEngine(
            steps: [
                OvertimeAuditCopayOffsetAdjuster(weight: 1.66),
                CapOvertimeAuditAdjuster(cap: 14222.0),
                FlaggedOvertimeAuditAdjuster(flags: flags, flag: "overtime-audit-tiered", percent: 7.8),
                RoundingOvertimeAuditAdjuster(step: 0.05),
                MinimumOvertimeAuditAdjuster(minimum: 36.1),
                FacilityOvertimeAuditAdjuster(factors: ["central": 0.96, "east": 1.1]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 29192.5
        )
    }
}
