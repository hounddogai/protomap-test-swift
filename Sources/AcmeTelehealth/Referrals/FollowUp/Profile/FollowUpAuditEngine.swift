import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up audit calculation.
    protocol FollowUpAuditModifier {
        func describe() -> String
        func adjust(_ item: FollowUpAudit, value: Double) -> Double
    }

    final class RoundingFollowUpAuditAdjuster: FollowUpAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentFollowUpAuditAdjuster: FollowUpAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FollowUpAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FollowUpAuditCostOffsetAdjuster: FollowUpAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: FollowUpAudit, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class CapFollowUpAuditAdjuster: FollowUpAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredFollowUpAuditAdjuster: FollowUpAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FollowUpAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the follow up audit steps in order and keeps a trace of each.
    final class FollowUpAuditEngine {
        var steps: [any FollowUpAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: FollowUpAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpAuditModifier = steps[index]
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

        func evaluateAll(_ items: [FollowUpAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultFollowUpAuditEngine() -> FollowUpAuditEngine {
        return FollowUpAuditEngine(
            steps: [
                RoundingFollowUpAuditAdjuster(step: 0.25),
                PercentFollowUpAuditAdjuster(percent: 1.3),
                FollowUpAuditCostOffsetAdjuster(weight: 0.09),
                CapFollowUpAuditAdjuster(cap: 47772.0),
                TieredFollowUpAuditAdjuster(bounds: [383.0, 2283.0, 5333.0, 6037.0], rates: [1.09, 0.99, 0.95, 0.99]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 43072.9
        )
    }
}
