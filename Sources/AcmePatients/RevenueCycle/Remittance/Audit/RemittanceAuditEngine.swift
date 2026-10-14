import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance audit calculation.
    protocol RemittanceAuditModifier {
        func describe() -> String
        func adjust(_ item: RemittanceAudit, value: Double) -> Double
    }

    final class CapRemittanceAuditAdjuster: RemittanceAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RemittanceAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRemittanceAuditAdjuster: RemittanceAuditModifier {
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

        func adjust(_ item: RemittanceAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRemittanceAuditAdjuster: RemittanceAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RemittanceAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRemittanceAuditAdjuster: RemittanceAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RemittanceAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the remittance audit steps in order and keeps a trace of each.
    final class RemittanceAuditEngine {
        var steps: [any RemittanceAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RemittanceAudit) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RemittanceAuditModifier = steps[index]
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

        func evaluateAll(_ items: [RemittanceAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRemittanceAuditEngine(_ flags: Kit.Flags.Registry) -> RemittanceAuditEngine {
        return RemittanceAuditEngine(
            steps: [
                CapRemittanceAuditAdjuster(cap: 2617.0),
                FlaggedRemittanceAuditAdjuster(flags: flags, flag: "remittance-audit-global", percent: -2.6),
                TieredRemittanceAuditAdjuster(
                    bounds: [5199.0, 8302.0, 9033.0, 9980.0],
                    rates: [0.95, 1.13, 1.08, 1.12]
                ),
                RoundingRemittanceAuditAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 62764.5
        )
    }
}
