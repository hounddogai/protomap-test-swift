import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled follow up manifest calculation.
    protocol ScheduledFollowUpManifestFactor {
        func describe() -> String
        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double
    }

    final class ScheduledFollowUpManifestGraceDaysOffsetAdjuster: ScheduledFollowUpManifestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TitleScheduledFollowUpManifestAdjuster: ScheduledFollowUpManifestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedScheduledFollowUpManifestAdjuster: ScheduledFollowUpManifestFactor {
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

        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledFollowUpManifestAdjuster: ScheduledFollowUpManifestFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledFollowUpManifestAdjuster: ScheduledFollowUpManifestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingScheduledFollowUpManifestAdjuster: ScheduledFollowUpManifestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledFollowUpManifest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled follow up manifest steps in order and keeps a trace of each.
    final class ScheduledFollowUpManifestEngine {
        var steps: [any ScheduledFollowUpManifestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledFollowUpManifestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledFollowUpManifest) -> Double {
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

        func evaluateAll(_ items: [ScheduledFollowUpManifest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledFollowUpManifestEngine(_ flags: Kit.Flags.Registry) -> ScheduledFollowUpManifestEngine {
        return ScheduledFollowUpManifestEngine(
            steps: [
                ScheduledFollowUpManifestGraceDaysOffsetAdjuster(weight: 0.06),
                TitleScheduledFollowUpManifestAdjuster(factors: ["south": 0.87, "central": 1.36, "east": 0.9]),
                FlaggedScheduledFollowUpManifestAdjuster(
                    flags: flags,
                    flag: "scheduled-follow-up-manifest-rolling",
                    percent: -5.9
                ),
                CapScheduledFollowUpManifestAdjuster(cap: 38282.0),
                TieredScheduledFollowUpManifestAdjuster(bounds: [1442.0, 2227.0, 7716.0], rates: [1.2, 0.81, 0.89]),
                RoundingScheduledFollowUpManifestAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 34252.8
        )
    }
}
