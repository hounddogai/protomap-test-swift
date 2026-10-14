import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the scheduled recall audit calculation.
    protocol ScheduledRecallAuditAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double
    }

    final class FlaggedScheduledRecallAuditAdjuster: ScheduledRecallAuditAdjuster {
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

        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledRecallAuditAdjuster: ScheduledRecallAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledRecallAuditAdjuster: ScheduledRecallAuditAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledRecallAuditDurationMinutesOffsetAdjuster: ScheduledRecallAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus duration minutes times \(weight)"
        }

        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double {
            return value + Double(item.durationMinutes) * weight
        }
    }

    final class LabelScheduledRecallAuditAdjuster: ScheduledRecallAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredScheduledRecallAuditAdjuster: ScheduledRecallAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRecallAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the scheduled recall audit steps in order and keeps a trace of each.
    final class ScheduledRecallAuditEngine {
        var steps: [any ScheduledRecallAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRecallAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledRecallAudit) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [ScheduledRecallAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledRecallAuditEngine(_ flags: Kit.Flags.Registry) -> ScheduledRecallAuditEngine {
        return ScheduledRecallAuditEngine(
            steps: [
                FlaggedScheduledRecallAuditAdjuster(flags: flags, flag: "scheduled-recall-audit-global", percent: 5.1),
                PercentScheduledRecallAuditAdjuster(percent: 3.0),
                CapScheduledRecallAuditAdjuster(cap: 9415.0),
                ScheduledRecallAuditDurationMinutesOffsetAdjuster(weight: 1.85),
                LabelScheduledRecallAuditAdjuster(factors: ["online": 0.83, "west": 0.96, "retail": 0.99]),
                TieredScheduledRecallAuditAdjuster(
                    bounds: [164.0, 489.0, 794.0, 3251.0],
                    rates: [1.09, 1.02, 0.98, 1.11]
                ),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 61029.6
        )
    }
}
