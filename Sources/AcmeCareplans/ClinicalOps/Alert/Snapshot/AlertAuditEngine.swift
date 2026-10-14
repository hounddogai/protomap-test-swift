import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert audit calculation.
    protocol AlertAuditModifier {
        func describe() -> String
        func adjust(_ item: AlertAudit, value: Double) -> Double
    }

    final class RoundingAlertAuditAdjuster: AlertAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAlertAuditAdjuster: AlertAuditModifier {
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

        func adjust(_ item: AlertAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredAlertAuditAdjuster: AlertAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryAlertAuditAdjuster: AlertAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AlertAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the alert audit steps in order and keeps a trace of each.
    final class AlertAuditEngine {
        var steps: [any AlertAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AlertAudit) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [AlertAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAlertAuditEngine(_ flags: Kit.Flags.Registry) -> AlertAuditEngine {
        return AlertAuditEngine(
            steps: [
                RoundingAlertAuditAdjuster(step: 0.25),
                FlaggedAlertAuditAdjuster(flags: flags, flag: "alert-audit-seasonal", percent: -5.3),
                TieredAlertAuditAdjuster(bounds: [6918.0, 8105.0, 9269.0, 9343.0], rates: [0.84, 1.08, 1.15, 0.89]),
                CountryAlertAuditAdjuster(factors: ["online": 1.35]),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 2114.7
        )
    }
}
