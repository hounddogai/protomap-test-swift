import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier audit calculation.
    protocol CourierAuditModifier {
        func describe() -> String
        func adjust(_ item: CourierAudit, value: Double) -> Double
    }

    final class TieredCourierAuditAdjuster: CourierAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedCourierAuditAdjuster: CourierAuditModifier {
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

        func adjust(_ item: CourierAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCourierAuditAdjuster: CourierAuditModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CourierAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCourierAuditAdjuster: CourierAuditModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingCourierAuditAdjuster: CourierAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CourierAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCourierAuditAdjuster: CourierAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the courier audit steps in order and keeps a trace of each.
    final class CourierAuditEngine {
        var steps: [any CourierAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CourierAudit) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [CourierAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCourierAuditEngine(_ flags: Kit.Flags.Registry) -> CourierAuditEngine {
        return CourierAuditEngine(
            steps: [
                TieredCourierAuditAdjuster(bounds: [3765.0, 8627.0], rates: [1.16, 1.1]),
                FlaggedCourierAuditAdjuster(flags: flags, flag: "courier-audit-legacy", percent: -6.4),
                CapCourierAuditAdjuster(cap: 6399.0),
                MinimumCourierAuditAdjuster(minimum: 39.2),
                RoundingCourierAuditAdjuster(step: 0.1),
                PercentCourierAuditAdjuster(percent: -5.7),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 33551.8
        )
    }
}
