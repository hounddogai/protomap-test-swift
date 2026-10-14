import AcmePlatform
import Foundation

extension Consent {
    /// One step of the scheduled revocation bundle calculation.
    protocol ScheduledRevocationBundleAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double
    }

    final class MinimumScheduledRevocationBundleAdjuster: ScheduledRevocationBundleAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedScheduledRevocationBundleAdjuster: ScheduledRevocationBundleAdjuster {
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

        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledRevocationBundleAdjuster: ScheduledRevocationBundleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredScheduledRevocationBundleAdjuster: ScheduledRevocationBundleAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentScheduledRevocationBundleAdjuster: ScheduledRevocationBundleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ScheduledRevocationBundleDosageMgOffsetAdjuster: ScheduledRevocationBundleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ScheduledRevocationBundle, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the scheduled revocation bundle steps in order and keeps a trace of each.
    final class ScheduledRevocationBundleEngine {
        var steps: [any ScheduledRevocationBundleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRevocationBundleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledRevocationBundle) -> Double {
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

        func evaluateAll(_ items: [ScheduledRevocationBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledRevocationBundleEngine(_ flags: Kit.Flags.Registry) -> ScheduledRevocationBundleEngine {
        return ScheduledRevocationBundleEngine(
            steps: [
                MinimumScheduledRevocationBundleAdjuster(minimum: 40.6),
                FlaggedScheduledRevocationBundleAdjuster(
                    flags: flags,
                    flag: "scheduled-revocation-bundle-capped",
                    percent: -4.1
                ),
                CapScheduledRevocationBundleAdjuster(cap: 10760.0),
                TieredScheduledRevocationBundleAdjuster(bounds: [1705.0, 2746.0, 9289.0], rates: [0.98, 0.99, 0.89]),
                PercentScheduledRevocationBundleAdjuster(percent: -11.3),
                ScheduledRevocationBundleDosageMgOffsetAdjuster(weight: 1.57),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 71963.7
        )
    }
}
