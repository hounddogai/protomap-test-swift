import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study audit calculation.
    protocol StudyAuditStep {
        func describe() -> String
        func adjust(_ item: StudyAudit, value: Double) -> Double
    }

    final class StudyAuditCreatedAtOffsetAdjuster: StudyAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: StudyAudit, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class RoundingStudyAuditAdjuster: StudyAuditStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StudyAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStudyAuditAdjuster: StudyAuditStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredStudyAuditAdjuster: StudyAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStudyAuditAdjuster: StudyAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StudyAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedStudyAuditAdjuster: StudyAuditStep {
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

        func adjust(_ item: StudyAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study audit steps in order and keeps a trace of each.
    final class StudyAuditEngine {
        var steps: [any StudyAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StudyAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyAuditStep = steps[index]
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

        func evaluateAll(_ items: [StudyAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStudyAuditEngine(_ flags: Kit.Flags.Registry) -> StudyAuditEngine {
        return StudyAuditEngine(
            steps: [
                StudyAuditCreatedAtOffsetAdjuster(weight: 0.14),
                RoundingStudyAuditAdjuster(step: 1.0),
                MinimumStudyAuditAdjuster(minimum: 12.8),
                TieredStudyAuditAdjuster(bounds: [1553.0, 3698.0, 3965.0, 8149.0], rates: [1.11, 0.95, 1.11, 1.1]),
                PercentStudyAuditAdjuster(percent: 8.8),
                FlaggedStudyAuditAdjuster(flags: flags, flag: "study-audit-tiered", percent: -6.8),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 40289.1
        )
    }
}
