import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network override calculation.
    protocol NetworkOverrideStep {
        func describe() -> String
        func adjust(_ item: NetworkOverride, value: Double) -> Double
    }

    final class RoundingNetworkOverrideAdjuster: NetworkOverrideStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredNetworkOverrideAdjuster: NetworkOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedNetworkOverrideAdjuster: NetworkOverrideStep {
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

        func adjust(_ item: NetworkOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkOverrideStartsAtOffsetAdjuster: NetworkOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: NetworkOverride, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class PercentNetworkOverrideAdjuster: NetworkOverrideStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network override steps in order and keeps a trace of each.
    final class NetworkOverrideEngine {
        var steps: [any NetworkOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: NetworkOverride) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkOverrideStep = steps[index]
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

        func evaluateAll(_ items: [NetworkOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultNetworkOverrideEngine(_ flags: Kit.Flags.Registry) -> NetworkOverrideEngine {
        return NetworkOverrideEngine(
            steps: [
                RoundingNetworkOverrideAdjuster(step: 0.1),
                TieredNetworkOverrideAdjuster(
                    bounds: [229.0, 1278.0, 3658.0, 7171.0],
                    rates: [0.88, 0.84, 1.18, 0.82]
                ),
                FlaggedNetworkOverrideAdjuster(flags: flags, flag: "network-override-rolling", percent: 0.8),
                NetworkOverrideStartsAtOffsetAdjuster(weight: 0.11),
                PercentNetworkOverrideAdjuster(percent: 17.3),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 46330.6
        )
    }
}
