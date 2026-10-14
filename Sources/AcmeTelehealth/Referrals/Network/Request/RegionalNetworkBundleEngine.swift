import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the regional network bundle calculation.
    protocol RegionalNetworkBundleFactor {
        func describe() -> String
        func adjust(_ item: RegionalNetworkBundle, value: Double) -> Double
    }

    final class CategoryRegionalNetworkBundleAdjuster: RegionalNetworkBundleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RegionalNetworkBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalNetworkBundleAdjuster: RegionalNetworkBundleFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalNetworkBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRegionalNetworkBundleAdjuster: RegionalNetworkBundleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalNetworkBundle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRegionalNetworkBundleAdjuster: RegionalNetworkBundleFactor {
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

        func adjust(_ item: RegionalNetworkBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalNetworkBundleAdjuster: RegionalNetworkBundleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalNetworkBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional network bundle steps in order and keeps a trace of each.
    final class RegionalNetworkBundleEngine {
        var steps: [any RegionalNetworkBundleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalNetworkBundleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalNetworkBundle) -> Double {
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

        func evaluateAll(_ items: [RegionalNetworkBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalNetworkBundleEngine(_ flags: Kit.Flags.Registry) -> RegionalNetworkBundleEngine {
        return RegionalNetworkBundleEngine(
            steps: [
                CategoryRegionalNetworkBundleAdjuster(factors: ["central": 1.02, "east": 0.78, "west": 1.17]),
                RoundingRegionalNetworkBundleAdjuster(step: 0.5),
                TieredRegionalNetworkBundleAdjuster(bounds: [577.0, 4168.0, 8253.0], rates: [1.15, 0.86, 0.9]),
                FlaggedRegionalNetworkBundleAdjuster(
                    flags: flags,
                    flag: "regional-network-bundle-seasonal",
                    percent: 0.6
                ),
                MinimumRegionalNetworkBundleAdjuster(minimum: 25.9),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 71969.9
        )
    }
}
