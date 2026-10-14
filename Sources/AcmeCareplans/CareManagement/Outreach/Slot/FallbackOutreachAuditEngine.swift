import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback outreach audit calculation.
    protocol FallbackOutreachAuditFactor {
        func describe() -> String
        func adjust(_ item: FallbackOutreachAudit, value: Double) -> Double
    }

    final class TieredFallbackOutreachAuditAdjuster: FallbackOutreachAuditFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackOutreachAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedFallbackOutreachAuditAdjuster: FallbackOutreachAuditFactor {
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

        func adjust(_ item: FallbackOutreachAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityFallbackOutreachAuditAdjuster: FallbackOutreachAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: FallbackOutreachAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FallbackOutreachAuditSequenceOffsetAdjuster: FallbackOutreachAuditFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: FallbackOutreachAudit, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    final class RoundingFallbackOutreachAuditAdjuster: FallbackOutreachAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackOutreachAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback outreach audit steps in order and keeps a trace of each.
    final class FallbackOutreachAuditEngine {
        var steps: [any FallbackOutreachAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackOutreachAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackOutreachAudit) -> Double {
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

        func evaluateAll(_ items: [FallbackOutreachAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackOutreachAuditEngine(_ flags: Kit.Flags.Registry) -> FallbackOutreachAuditEngine {
        return FallbackOutreachAuditEngine(
            steps: [
                TieredFallbackOutreachAuditAdjuster(
                    bounds: [4050.0, 5236.0, 8515.0, 9465.0],
                    rates: [1.19, 0.88, 1.04, 1.14]
                ),
                FlaggedFallbackOutreachAuditAdjuster(
                    flags: flags,
                    flag: "fallback-outreach-audit-primary",
                    percent: -4.2
                ),
                FacilityFallbackOutreachAuditAdjuster(factors: ["north": 0.88, "online": 1.3, "central": 1.37]),
                FallbackOutreachAuditSequenceOffsetAdjuster(weight: 0.14),
                RoundingFallbackOutreachAuditAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 17741.1
        )
    }
}
