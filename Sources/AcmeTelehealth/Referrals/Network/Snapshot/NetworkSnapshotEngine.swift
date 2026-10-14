import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network snapshot calculation.
    protocol NetworkSnapshotStep {
        func describe() -> String
        func adjust(_ item: NetworkSnapshot, value: Double) -> Double
    }

    final class NetworkSnapshotWeightOffsetAdjuster: NetworkSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: NetworkSnapshot, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class PercentNetworkSnapshotAdjuster: NetworkSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapNetworkSnapshotAdjuster: NetworkSnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingNetworkSnapshotAdjuster: NetworkSnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredNetworkSnapshotAdjuster: NetworkSnapshotStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedNetworkSnapshotAdjuster: NetworkSnapshotStep {
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

        func adjust(_ item: NetworkSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network snapshot steps in order and keeps a trace of each.
    final class NetworkSnapshotEngine {
        var steps: [any NetworkSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkSnapshot) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [NetworkSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkSnapshotEngine(_ flags: Kit.Flags.Registry) -> NetworkSnapshotEngine {
        return NetworkSnapshotEngine(
            steps: [
                NetworkSnapshotWeightOffsetAdjuster(weight: 0.79),
                PercentNetworkSnapshotAdjuster(percent: 11.3),
                CapNetworkSnapshotAdjuster(cap: 30319.0),
                RoundingNetworkSnapshotAdjuster(step: 5.0),
                TieredNetworkSnapshotAdjuster(bounds: [578.0, 9674.0], rates: [1.1, 1.08]),
                FlaggedNetworkSnapshotAdjuster(flags: flags, flag: "network-snapshot-batched", percent: 4.3),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 75644.4
        )
    }
}
