import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled network bundle calculation.
    protocol ScheduledNetworkBundleModifier {
        func describe() -> String
        func adjust(_ item: ScheduledNetworkBundle, value: Double) -> Double
    }

    final class FlaggedScheduledNetworkBundleAdjuster: ScheduledNetworkBundleModifier {
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

        func adjust(_ item: ScheduledNetworkBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelScheduledNetworkBundleAdjuster: ScheduledNetworkBundleModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: ScheduledNetworkBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentScheduledNetworkBundleAdjuster: ScheduledNetworkBundleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledNetworkBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledNetworkBundleAdjuster: ScheduledNetworkBundleModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledNetworkBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumScheduledNetworkBundleAdjuster: ScheduledNetworkBundleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledNetworkBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the scheduled network bundle steps in order and keeps a trace of each.
    final class ScheduledNetworkBundleEngine {
        var steps: [any ScheduledNetworkBundleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledNetworkBundleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledNetworkBundle) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [ScheduledNetworkBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledNetworkBundleEngine(_ flags: Kit.Flags.Registry) -> ScheduledNetworkBundleEngine {
        return ScheduledNetworkBundleEngine(
            steps: [
                FlaggedScheduledNetworkBundleAdjuster(
                    flags: flags,
                    flag: "scheduled-network-bundle-rolling",
                    percent: -3.4
                ),
                LabelScheduledNetworkBundleAdjuster(factors: ["central": 1.37, "north": 0.81]),
                PercentScheduledNetworkBundleAdjuster(percent: -11.3),
                TieredScheduledNetworkBundleAdjuster(bounds: [5006.0, 5483.0, 7476.0], rates: [1.19, 0.81, 1.06]),
                MinimumScheduledNetworkBundleAdjuster(minimum: 34.6),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 44086.8
        )
    }
}
