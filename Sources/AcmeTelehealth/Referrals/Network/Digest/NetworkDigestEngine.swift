import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network digest calculation.
    protocol NetworkDigestAdjuster {
        func describe() -> String
        func adjust(_ item: NetworkDigest, value: Double) -> Double
    }

    final class CapNetworkDigestAdjuster: NetworkDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedNetworkDigestAdjuster: NetworkDigestAdjuster {
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

        func adjust(_ item: NetworkDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkDigestAdjuster: NetworkDigestAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkDigest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingNetworkDigestAdjuster: NetworkDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NetworkDigestCapacityOffsetAdjuster: NetworkDigestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: NetworkDigest, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredNetworkDigestAdjuster: NetworkDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the network digest steps in order and keeps a trace of each.
    final class NetworkDigestEngine {
        var steps: [any NetworkDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkDigest) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkDigestAdjuster = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [NetworkDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkDigestEngine(_ flags: Kit.Flags.Registry) -> NetworkDigestEngine {
        return NetworkDigestEngine(
            steps: [
                CapNetworkDigestAdjuster(cap: 13011.0),
                FlaggedNetworkDigestAdjuster(flags: flags, flag: "network-digest-rolling", percent: -6.6),
                MinimumNetworkDigestAdjuster(minimum: 45.3),
                RoundingNetworkDigestAdjuster(step: 1.0),
                NetworkDigestCapacityOffsetAdjuster(weight: 0.86),
                TieredNetworkDigestAdjuster(bounds: [2110.0, 2193.0, 4741.0, 7577.0], rates: [1.12, 0.98, 1.18, 0.92]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 45313.7
        )
    }
}
