import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the rolling denial audit calculation.
    protocol RollingDenialAuditModifier {
        func describe() -> String
        func adjust(_ item: RollingDenialAudit, value: Double) -> Double
    }

    final class CapRollingDenialAuditAdjuster: RollingDenialAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingDenialAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredRollingDenialAuditAdjuster: RollingDenialAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingDenialAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingDenialAuditAdjuster: RollingDenialAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingDenialAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the rolling denial audit steps in order and keeps a trace of each.
    final class RollingDenialAuditEngine {
        var steps: [any RollingDenialAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingDenialAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingDenialAudit) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [RollingDenialAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingDenialAuditEngine() -> RollingDenialAuditEngine {
        return RollingDenialAuditEngine(
            steps: [
                CapRollingDenialAuditAdjuster(cap: 928.0),
                TieredRollingDenialAuditAdjuster(bounds: [4008.0, 4810.0], rates: [0.9, 0.94]),
                RoundingRollingDenialAuditAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 87392.3
        )
    }
}
