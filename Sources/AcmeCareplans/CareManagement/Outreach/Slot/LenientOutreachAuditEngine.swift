import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient outreach audit calculation.
    protocol LenientOutreachAuditModifier {
        func describe() -> String
        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double
    }

    final class RoundingLenientOutreachAuditAdjuster: LenientOutreachAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredLenientOutreachAuditAdjuster: LenientOutreachAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedLenientOutreachAuditAdjuster: LenientOutreachAuditModifier {
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

        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientOutreachAuditAdjuster: LenientOutreachAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientOutreachAuditAdjuster: LenientOutreachAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientOutreachAuditAdjuster: LenientOutreachAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientOutreachAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient outreach audit steps in order and keeps a trace of each.
    final class LenientOutreachAuditEngine {
        var steps: [any LenientOutreachAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientOutreachAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientOutreachAudit) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientOutreachAuditModifier = steps[index]
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

        func evaluateAll(_ items: [LenientOutreachAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientOutreachAuditEngine(_ flags: Kit.Flags.Registry) -> LenientOutreachAuditEngine {
        return LenientOutreachAuditEngine(
            steps: [
                RoundingLenientOutreachAuditAdjuster(step: 0.25),
                TieredLenientOutreachAuditAdjuster(
                    bounds: [1762.0, 2926.0, 4526.0, 7932.0],
                    rates: [0.95, 0.88, 1.14, 0.89]
                ),
                FlaggedLenientOutreachAuditAdjuster(
                    flags: flags,
                    flag: "lenient-outreach-audit-legacy",
                    percent: -2.9
                ),
                PercentLenientOutreachAuditAdjuster(percent: 22.2),
                MinimumLenientOutreachAuditAdjuster(minimum: 12.3),
                CapLenientOutreachAuditAdjuster(cap: 33194.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 90722.0
        )
    }
}
