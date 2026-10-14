import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled follow up audit calculation.
    protocol ScheduledFollowUpAuditAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledFollowUpAudit, value: Double) -> Double
    }

    final class TieredScheduledFollowUpAuditAdjuster: ScheduledFollowUpAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledFollowUpAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleScheduledFollowUpAuditAdjuster: ScheduledFollowUpAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledFollowUpAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumScheduledFollowUpAuditAdjuster: ScheduledFollowUpAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledFollowUpAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapScheduledFollowUpAuditAdjuster: ScheduledFollowUpAuditAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledFollowUpAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled follow up audit steps in order and keeps a trace of each.
    final class ScheduledFollowUpAuditEngine {
        var steps: [any ScheduledFollowUpAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFollowUpAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ScheduledFollowUpAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledFollowUpAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [ScheduledFollowUpAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultScheduledFollowUpAuditEngine() -> ScheduledFollowUpAuditEngine {
        return ScheduledFollowUpAuditEngine(
            steps: [
                TieredScheduledFollowUpAuditAdjuster(
                    bounds: [526.0, 6050.0, 8995.0, 9379.0],
                    rates: [0.89, 1.03, 1.02, 0.81]
                ),
                TitleScheduledFollowUpAuditAdjuster(factors: ["south": 0.89]),
                MinimumScheduledFollowUpAuditAdjuster(minimum: 35.2),
                CapScheduledFollowUpAuditAdjuster(cap: 11046.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 62811.4
        )
    }
}
