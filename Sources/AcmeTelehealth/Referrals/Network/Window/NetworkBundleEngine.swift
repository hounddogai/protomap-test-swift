import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network bundle calculation.
    protocol NetworkBundleStep {
        func describe() -> String
        func adjust(_ item: NetworkBundle, value: Double) -> Double
    }

    final class PercentNetworkBundleAdjuster: NetworkBundleStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkBundle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionNetworkBundleAdjuster: NetworkBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: NetworkBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class NetworkBundleAmountOffsetAdjuster: NetworkBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: NetworkBundle, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedNetworkBundleAdjuster: NetworkBundleStep {
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

        func adjust(_ item: NetworkBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network bundle steps in order and keeps a trace of each.
    final class NetworkBundleEngine {
        var steps: [any NetworkBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkBundle) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [NetworkBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkBundleEngine(_ flags: Kit.Flags.Registry) -> NetworkBundleEngine {
        return NetworkBundleEngine(
            steps: [
                PercentNetworkBundleAdjuster(percent: 13.2),
                RegionNetworkBundleAdjuster(factors: ["online": 1.06, "retail": 1.29]),
                NetworkBundleAmountOffsetAdjuster(weight: 0.64),
                FlaggedNetworkBundleAdjuster(flags: flags, flag: "network-bundle-scheduled", percent: -1.4),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 17665.4
        )
    }
}
