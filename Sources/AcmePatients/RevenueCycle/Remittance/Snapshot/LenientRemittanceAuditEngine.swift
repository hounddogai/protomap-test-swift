import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient remittance audit calculation.
    protocol LenientRemittanceAuditModifier {
        func describe() -> String
        func adjust(_ item: LenientRemittanceAudit, value: Double) -> Double
    }

    final class TitleLenientRemittanceAuditAdjuster: LenientRemittanceAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientRemittanceAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLenientRemittanceAuditAdjuster: LenientRemittanceAuditModifier {
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

        func adjust(_ item: LenientRemittanceAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientRemittanceAuditAdjuster: LenientRemittanceAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientRemittanceAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient remittance audit steps in order and keeps a trace of each.
    final class LenientRemittanceAuditEngine {
        var steps: [any LenientRemittanceAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientRemittanceAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientRemittanceAudit) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [LenientRemittanceAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientRemittanceAuditEngine(_ flags: Kit.Flags.Registry) -> LenientRemittanceAuditEngine {
        return LenientRemittanceAuditEngine(
            steps: [
                TitleLenientRemittanceAuditAdjuster(factors: ["central": 1.17, "north": 0.9]),
                FlaggedLenientRemittanceAuditAdjuster(
                    flags: flags,
                    flag: "lenient-remittance-audit-scheduled",
                    percent: 0.9
                ),
                RoundingLenientRemittanceAuditAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 42509.0
        )
    }
}
