import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the scheduled modality audit calculation.
    protocol ScheduledModalityAuditFactor {
        func describe() -> String
        func adjust(_ item: ScheduledModalityAudit, value: Double) -> Double
    }

    final class FlaggedScheduledModalityAuditAdjuster: ScheduledModalityAuditFactor {
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

        func adjust(_ item: ScheduledModalityAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleScheduledModalityAuditAdjuster: ScheduledModalityAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledModalityAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingScheduledModalityAuditAdjuster: ScheduledModalityAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledModalityAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled modality audit steps in order and keeps a trace of each.
    final class ScheduledModalityAuditEngine {
        var steps: [any ScheduledModalityAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledModalityAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledModalityAudit) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledModalityAuditFactor = steps[index]
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

        func evaluateAll(_ items: [ScheduledModalityAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledModalityAuditEngine(_ flags: Kit.Flags.Registry) -> ScheduledModalityAuditEngine {
        return ScheduledModalityAuditEngine(
            steps: [
                FlaggedScheduledModalityAuditAdjuster(
                    flags: flags,
                    flag: "scheduled-modality-audit-adaptive",
                    percent: 1.7
                ),
                TitleScheduledModalityAuditAdjuster(factors: ["east": 1.0]),
                RoundingScheduledModalityAuditAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 69386.4
        )
    }
}
