import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network slot calculation.
    protocol NetworkSlotModifier {
        func describe() -> String
        func adjust(_ item: NetworkSlot, value: Double) -> Double
    }

    final class TieredNetworkSlotAdjuster: NetworkSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumNetworkSlotAdjuster: NetworkSlotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: NetworkSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapNetworkSlotAdjuster: NetworkSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelNetworkSlotAdjuster: NetworkSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: NetworkSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedNetworkSlotAdjuster: NetworkSlotModifier {
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

        func adjust(_ item: NetworkSlot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentNetworkSlotAdjuster: NetworkSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network slot steps in order and keeps a trace of each.
    final class NetworkSlotEngine {
        var steps: [any NetworkSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkSlot) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkSlotModifier = steps[index]
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

        func evaluateAll(_ items: [NetworkSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkSlotEngine(_ flags: Kit.Flags.Registry) -> NetworkSlotEngine {
        return NetworkSlotEngine(
            steps: [
                TieredNetworkSlotAdjuster(bounds: [2679.0, 3735.0], rates: [1.04, 1.02]),
                MinimumNetworkSlotAdjuster(minimum: 43.3),
                CapNetworkSlotAdjuster(cap: 39296.0),
                LabelNetworkSlotAdjuster(factors: ["online": 1.26, "north": 1.29, "east": 0.84]),
                FlaggedNetworkSlotAdjuster(flags: flags, flag: "network-slot-tiered", percent: 9.6),
                PercentNetworkSlotAdjuster(percent: 17.7),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 87631.1
        )
    }
}
