import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network cycle calculation.
    protocol NetworkCycleFactor {
        func describe() -> String
        func adjust(_ item: NetworkCycle, value: Double) -> Double
    }

    final class PercentNetworkCycleAdjuster: NetworkCycleFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumNetworkCycleAdjuster: NetworkCycleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredNetworkCycleAdjuster: NetworkCycleFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkCycle, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapNetworkCycleAdjuster: NetworkCycleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkCycle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedNetworkCycleAdjuster: NetworkCycleFactor {
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

        func adjust(_ item: NetworkCycle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network cycle steps in order and keeps a trace of each.
    final class NetworkCycleEngine {
        var steps: [any NetworkCycleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkCycleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: NetworkCycle) -> Double {
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

        func evaluateAll(_ items: [NetworkCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultNetworkCycleEngine(_ flags: Kit.Flags.Registry) -> NetworkCycleEngine {
        return NetworkCycleEngine(
            steps: [
                PercentNetworkCycleAdjuster(percent: -9.0),
                MinimumNetworkCycleAdjuster(minimum: 6.2),
                TieredNetworkCycleAdjuster(bounds: [5005.0, 5080.0], rates: [1.14, 0.89]),
                CapNetworkCycleAdjuster(cap: 8485.0),
                FlaggedNetworkCycleAdjuster(flags: flags, flag: "network-cycle-fallback", percent: -5.1),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 16119.6
        )
    }
}
