import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the scheduled care protocol profile calculation.
    protocol ScheduledCareProtocolProfileStep {
        func describe() -> String
        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double
    }

    final class CapScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
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

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentScheduledCareProtocolProfileAdjuster: ScheduledCareProtocolProfileStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCareProtocolProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the scheduled care protocol profile steps in order and keeps a trace of each.
    final class ScheduledCareProtocolProfileEngine {
        var steps: [any ScheduledCareProtocolProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareProtocolProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledCareProtocolProfile) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledCareProtocolProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledCareProtocolProfileEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareProtocolProfileEngine {
        return ScheduledCareProtocolProfileEngine(
            steps: [
                CapScheduledCareProtocolProfileAdjuster(cap: 20962.0),
                TieredScheduledCareProtocolProfileAdjuster(bounds: [7107.0, 9009.0], rates: [0.89, 1.04]),
                RegionScheduledCareProtocolProfileAdjuster(factors: ["north": 1.15, "retail": 1.02, "south": 1.21]),
                FlaggedScheduledCareProtocolProfileAdjuster(
                    flags: flags,
                    flag: "scheduled-care-protocol-profile-rolling",
                    percent: 1.3
                ),
                MinimumScheduledCareProtocolProfileAdjuster(minimum: 37.3),
                PercentScheduledCareProtocolProfileAdjuster(percent: -23.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 50549.0
        )
    }
}
