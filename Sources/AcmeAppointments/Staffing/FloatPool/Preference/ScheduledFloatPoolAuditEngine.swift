import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the scheduled float pool audit calculation.
    protocol ScheduledFloatPoolAuditFactor {
        func describe() -> String
        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double
    }

    final class MinimumScheduledFloatPoolAuditAdjuster: ScheduledFloatPoolAuditFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledFloatPoolAuditAdjuster: ScheduledFloatPoolAuditFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ChannelScheduledFloatPoolAuditAdjuster: ScheduledFloatPoolAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledFloatPoolAuditQuantityOffsetAdjuster: ScheduledFloatPoolAuditFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class FlaggedScheduledFloatPoolAuditAdjuster: ScheduledFloatPoolAuditFactor {
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

        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledFloatPoolAuditAdjuster: ScheduledFloatPoolAuditFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledFloatPoolAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled float pool audit steps in order and keeps a trace of each.
    final class ScheduledFloatPoolAuditEngine {
        var steps: [any ScheduledFloatPoolAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFloatPoolAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledFloatPoolAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFloatPoolAuditFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledFloatPoolAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledFloatPoolAuditEngine(_ flags: Kit.Flags.Registry) -> ScheduledFloatPoolAuditEngine {
        return ScheduledFloatPoolAuditEngine(
            steps: [
                MinimumScheduledFloatPoolAuditAdjuster(minimum: 32.3),
                PercentScheduledFloatPoolAuditAdjuster(percent: -17.4),
                ChannelScheduledFloatPoolAuditAdjuster(factors: ["online": 1.3, "east": 0.92]),
                ScheduledFloatPoolAuditQuantityOffsetAdjuster(weight: 0.61),
                FlaggedScheduledFloatPoolAuditAdjuster(
                    flags: flags,
                    flag: "scheduled-float-pool-audit-fallback",
                    percent: 1.1
                ),
                CapScheduledFloatPoolAuditAdjuster(cap: 17523.0),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 9499.6
        )
    }
}
