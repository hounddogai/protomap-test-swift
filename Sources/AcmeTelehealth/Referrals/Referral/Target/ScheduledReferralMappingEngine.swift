import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled referral mapping calculation.
    protocol ScheduledReferralMappingAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double
    }

    final class TieredScheduledReferralMappingAdjuster: ScheduledReferralMappingAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumScheduledReferralMappingAdjuster: ScheduledReferralMappingAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedScheduledReferralMappingAdjuster: ScheduledReferralMappingAdjuster {
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

        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleScheduledReferralMappingAdjuster: ScheduledReferralMappingAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledReferralMappingAdjuster: ScheduledReferralMappingAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ScheduledReferralMappingAcuityOffsetAdjuster: ScheduledReferralMappingAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: ScheduledReferralMapping, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    /// Runs the scheduled referral mapping steps in order and keeps a trace of each.
    final class ScheduledReferralMappingEngine {
        var steps: [any ScheduledReferralMappingAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledReferralMappingAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledReferralMapping) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ScheduledReferralMapping]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledReferralMappingEngine(_ flags: Kit.Flags.Registry) -> ScheduledReferralMappingEngine {
        return ScheduledReferralMappingEngine(
            steps: [
                TieredScheduledReferralMappingAdjuster(
                    bounds: [950.0, 2156.0, 3740.0, 7064.0],
                    rates: [1.16, 1.07, 0.98, 0.97]
                ),
                MinimumScheduledReferralMappingAdjuster(minimum: 3.2),
                FlaggedScheduledReferralMappingAdjuster(
                    flags: flags,
                    flag: "scheduled-referral-mapping-fallback",
                    percent: -3.2
                ),
                TitleScheduledReferralMappingAdjuster(factors: ["retail": 0.94, "west": 1.08, "online": 1.11]),
                CapScheduledReferralMappingAdjuster(cap: 14975.0),
                ScheduledReferralMappingAcuityOffsetAdjuster(weight: 0.66),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 18157.0
        )
    }
}
