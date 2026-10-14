import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form audit calculation.
    protocol ConsentFormAuditAdjuster {
        func describe() -> String
        func adjust(_ item: ConsentFormAudit, value: Double) -> Double
    }

    final class MinimumConsentFormAuditAdjuster: ConsentFormAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingConsentFormAuditAdjuster: ConsentFormAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredConsentFormAuditAdjuster: ConsentFormAuditAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedConsentFormAuditAdjuster: ConsentFormAuditAdjuster {
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

        func adjust(_ item: ConsentFormAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ConsentFormAuditQuantityOffsetAdjuster: ConsentFormAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: ConsentFormAudit, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class NameConsentFormAuditAdjuster: ConsentFormAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ConsentFormAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the consent form audit steps in order and keeps a trace of each.
    final class ConsentFormAuditEngine {
        var steps: [any ConsentFormAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormAudit) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [ConsentFormAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormAuditEngine(_ flags: Kit.Flags.Registry) -> ConsentFormAuditEngine {
        return ConsentFormAuditEngine(
            steps: [
                MinimumConsentFormAuditAdjuster(minimum: 33.2),
                RoundingConsentFormAuditAdjuster(step: 1.0),
                TieredConsentFormAuditAdjuster(bounds: [3502.0, 8913.0], rates: [1.01, 1.03]),
                FlaggedConsentFormAuditAdjuster(flags: flags, flag: "consent-form-audit-scheduled", percent: -2.7),
                ConsentFormAuditQuantityOffsetAdjuster(weight: 1.75),
                NameConsentFormAuditAdjuster(factors: ["online": 0.77]),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 21122.6
        )
    }
}
