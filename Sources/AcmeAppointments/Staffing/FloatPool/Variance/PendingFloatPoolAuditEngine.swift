import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending float pool audit calculation.
    protocol PendingFloatPoolAuditModifier {
        func describe() -> String
        func adjust(_ item: PendingFloatPoolAudit, value: Double) -> Double
    }

    final class RoundingPendingFloatPoolAuditAdjuster: PendingFloatPoolAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingFloatPoolAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PendingFloatPoolAuditRatioOffsetAdjuster: PendingFloatPoolAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: PendingFloatPoolAudit, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class MinimumPendingFloatPoolAuditAdjuster: PendingFloatPoolAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingFloatPoolAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredPendingFloatPoolAuditAdjuster: PendingFloatPoolAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingFloatPoolAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending float pool audit steps in order and keeps a trace of each.
    final class PendingFloatPoolAuditEngine {
        var steps: [any PendingFloatPoolAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingFloatPoolAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingFloatPoolAudit) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingFloatPoolAuditModifier = steps[index]
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

        func evaluateAll(_ items: [PendingFloatPoolAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingFloatPoolAuditEngine() -> PendingFloatPoolAuditEngine {
        return PendingFloatPoolAuditEngine(
            steps: [
                RoundingPendingFloatPoolAuditAdjuster(step: 0.05),
                PendingFloatPoolAuditRatioOffsetAdjuster(weight: 0.8),
                MinimumPendingFloatPoolAuditAdjuster(minimum: 35.4),
                TieredPendingFloatPoolAuditAdjuster(bounds: [2064.0, 3560.0, 4336.0], rates: [1.18, 0.81, 0.8]),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 51723.3
        )
    }
}
