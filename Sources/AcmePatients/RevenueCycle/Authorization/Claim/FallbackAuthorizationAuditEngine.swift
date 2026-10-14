import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback authorization audit calculation.
    protocol FallbackAuthorizationAuditModifier {
        func describe() -> String
        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double
    }

    final class UnitFallbackAuthorizationAuditAdjuster: FallbackAuthorizationAuditModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredFallbackAuthorizationAuditAdjuster: FallbackAuthorizationAuditModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackAuthorizationAuditScoreOffsetAdjuster: FallbackAuthorizationAuditModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class RoundingFallbackAuthorizationAuditAdjuster: FallbackAuthorizationAuditModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackAuthorizationAuditAdjuster: FallbackAuthorizationAuditModifier {
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

        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackAuthorizationAuditAdjuster: FallbackAuthorizationAuditModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackAuthorizationAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback authorization audit steps in order and keeps a trace of each.
    final class FallbackAuthorizationAuditEngine {
        var steps: [any FallbackAuthorizationAuditModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAuthorizationAuditModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackAuthorizationAudit) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [FallbackAuthorizationAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackAuthorizationAuditEngine(_ flags: Kit.Flags.Registry) -> FallbackAuthorizationAuditEngine {
        return FallbackAuthorizationAuditEngine(
            steps: [
                UnitFallbackAuthorizationAuditAdjuster(factors: ["online": 1.15, "central": 0.77, "east": 1.26]),
                TieredFallbackAuthorizationAuditAdjuster(bounds: [7122.0, 8704.0], rates: [0.97, 1.0]),
                FallbackAuthorizationAuditScoreOffsetAdjuster(weight: 1.79),
                RoundingFallbackAuthorizationAuditAdjuster(step: 0.25),
                FlaggedFallbackAuthorizationAuditAdjuster(
                    flags: flags,
                    flag: "fallback-authorization-audit-rolling",
                    percent: -6.5
                ),
                PercentFallbackAuthorizationAuditAdjuster(percent: -10.9),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 87480.3
        )
    }
}
