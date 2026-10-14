import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff audit calculation.
    protocol HandoffAuditModifier {
        func describe() -> String
        func adjust(_ item: HandoffAudit, value: Double) -> Double
    }

    final class HandoffAuditCeilingOffsetAdjuster: HandoffAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: HandoffAudit, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class ChannelHandoffAuditAdjuster: HandoffAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: HandoffAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumHandoffAuditAdjuster: HandoffAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingHandoffAuditAdjuster: HandoffAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: HandoffAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredHandoffAuditAdjuster: HandoffAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: HandoffAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentHandoffAuditAdjuster: HandoffAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: HandoffAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff audit steps in order and keeps a trace of each.
    final class HandoffAuditEngine {
        var steps: [any HandoffAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: HandoffAudit) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any HandoffAuditModifier = steps[index]
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

        func evaluateAll(_ items: [HandoffAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultHandoffAuditEngine() -> HandoffAuditEngine {
        return HandoffAuditEngine(
            steps: [
                HandoffAuditCeilingOffsetAdjuster(weight: 1.89),
                ChannelHandoffAuditAdjuster(factors: ["east": 0.91, "north": 1.25]),
                MinimumHandoffAuditAdjuster(minimum: 25.6),
                RoundingHandoffAuditAdjuster(step: 5.0),
                TieredHandoffAuditAdjuster(bounds: [1760.0, 7476.0, 9821.0], rates: [0.86, 1.16, 1.07]),
                PercentHandoffAuditAdjuster(percent: 4.9),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 68163.1
        )
    }
}
