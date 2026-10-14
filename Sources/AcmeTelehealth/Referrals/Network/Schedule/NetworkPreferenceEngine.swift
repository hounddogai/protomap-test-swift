import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network preference calculation.
    protocol NetworkPreferenceStep {
        func describe() -> String
        func adjust(_ item: NetworkPreference, value: Double) -> Double
    }

    final class FlaggedNetworkPreferenceAdjuster: NetworkPreferenceStep {
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

        func adjust(_ item: NetworkPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkPreferenceMaximumOffsetAdjuster: NetworkPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: NetworkPreference, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class PercentNetworkPreferenceAdjuster: NetworkPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network preference steps in order and keeps a trace of each.
    final class NetworkPreferenceEngine {
        var steps: [any NetworkPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: NetworkPreference) -> Double {
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

        func evaluateAll(_ items: [NetworkPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultNetworkPreferenceEngine(_ flags: Kit.Flags.Registry) -> NetworkPreferenceEngine {
        return NetworkPreferenceEngine(
            steps: [
                FlaggedNetworkPreferenceAdjuster(flags: flags, flag: "network-preference-manual", percent: -8.6),
                NetworkPreferenceMaximumOffsetAdjuster(weight: 0.08),
                PercentNetworkPreferenceAdjuster(percent: 24.5),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 6988.5
        )
    }
}
