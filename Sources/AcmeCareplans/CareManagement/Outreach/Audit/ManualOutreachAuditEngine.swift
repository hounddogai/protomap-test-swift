import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual outreach audit calculation.
    protocol ManualOutreachAuditAdjuster {
        func describe() -> String
        func adjust(_ item: ManualOutreachAudit, value: Double) -> Double
    }

    final class ManualOutreachAuditDurationMinutesOffsetAdjuster: ManualOutreachAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ManualOutreachAudit, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class PercentManualOutreachAuditAdjuster: ManualOutreachAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualOutreachAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualOutreachAuditAdjuster: ManualOutreachAuditAdjuster {
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

        func adjust(_ item: ManualOutreachAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualOutreachAuditAdjuster: ManualOutreachAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualOutreachAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the manual outreach audit steps in order and keeps a trace of each.
    final class ManualOutreachAuditEngine {
        var steps: [any ManualOutreachAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualOutreachAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualOutreachAudit) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualOutreachAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [ManualOutreachAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualOutreachAuditEngine(_ flags: Kit.Flags.Registry) -> ManualOutreachAuditEngine {
        return ManualOutreachAuditEngine(
            steps: [
                ManualOutreachAuditDurationMinutesOffsetAdjuster(weight: 1.07),
                PercentManualOutreachAuditAdjuster(percent: -22.1),
                FlaggedManualOutreachAuditAdjuster(flags: flags, flag: "manual-outreach-audit-global", percent: -1.7),
                TieredManualOutreachAuditAdjuster(bounds: [7019.0, 9939.0], rates: [1.15, 0.86]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 58122.0
        )
    }
}
