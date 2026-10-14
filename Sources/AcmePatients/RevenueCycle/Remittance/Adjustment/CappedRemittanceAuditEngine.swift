import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the capped remittance audit calculation.
    protocol CappedRemittanceAuditModifier {
        func describe() -> String
        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double
    }

    final class CappedRemittanceAuditAmountOffsetAdjuster: CappedRemittanceAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class CapCappedRemittanceAuditAdjuster: CappedRemittanceAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCappedRemittanceAuditAdjuster: CappedRemittanceAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCappedRemittanceAuditAdjuster: CappedRemittanceAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class WardCappedRemittanceAuditAdjuster: CappedRemittanceAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedCappedRemittanceAuditAdjuster: CappedRemittanceAuditModifier {
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

        func adjust(_ item: CappedRemittanceAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped remittance audit steps in order and keeps a trace of each.
    final class CappedRemittanceAuditEngine {
        var steps: [any CappedRemittanceAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedRemittanceAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedRemittanceAudit) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [CappedRemittanceAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedRemittanceAuditEngine(_ flags: Kit.Flags.Registry) -> CappedRemittanceAuditEngine {
        return CappedRemittanceAuditEngine(
            steps: [
                CappedRemittanceAuditAmountOffsetAdjuster(weight: 0.96),
                CapCappedRemittanceAuditAdjuster(cap: 10980.0),
                MinimumCappedRemittanceAuditAdjuster(minimum: 30.7),
                RoundingCappedRemittanceAuditAdjuster(step: 0.1),
                WardCappedRemittanceAuditAdjuster(factors: ["west": 0.95, "retail": 0.93]),
                FlaggedCappedRemittanceAuditAdjuster(
                    flags: flags,
                    flag: "capped-remittance-audit-regional",
                    percent: -6.8
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 24495.6
        )
    }
}
