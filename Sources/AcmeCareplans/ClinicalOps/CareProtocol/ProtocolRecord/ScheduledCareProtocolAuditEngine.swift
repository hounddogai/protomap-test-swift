import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled care protocol audit calculation.
    protocol ScheduledCareProtocolAuditStep {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolAudit, value: Double) -> Double
    }

    final class RoundingScheduledCareProtocolAuditAdjuster: ScheduledCareProtocolAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledCareProtocolAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapScheduledCareProtocolAuditAdjuster: ScheduledCareProtocolAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareProtocolAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ChannelScheduledCareProtocolAuditAdjuster: ScheduledCareProtocolAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: ScheduledCareProtocolAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledCareProtocolAuditAdjuster: ScheduledCareProtocolAuditStep {
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

        func adjust(_ item: ScheduledCareProtocolAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled care protocol audit steps in order and keeps a trace of each.
    final class ScheduledCareProtocolAuditEngine {
        var steps: [any ScheduledCareProtocolAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledCareProtocolAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledCareProtocolAuditStep = steps[index]
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

        func evaluateAll(_ items: [ScheduledCareProtocolAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolAuditEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareProtocolAuditEngine {
        return ScheduledCareProtocolAuditEngine(
            steps: [
                RoundingScheduledCareProtocolAuditAdjuster(step: 0.25),
                CapScheduledCareProtocolAuditAdjuster(cap: 5398.0),
                ChannelScheduledCareProtocolAuditAdjuster(factors: ["north": 1.38]),
                FlaggedScheduledCareProtocolAuditAdjuster(
                    flags: flags,
                    flag: "scheduled-care-protocol-audit-legacy",
                    percent: 6.9
                ),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 88244.8
        )
    }
}
