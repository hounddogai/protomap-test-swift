import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network target calculation.
    protocol NetworkTargetModifier {
        func describe() -> String
        func adjust(_ item: NetworkTarget, value: Double) -> Double
    }

    final class CapNetworkTargetAdjuster: NetworkTargetModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: NetworkTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredNetworkTargetAdjuster: NetworkTargetModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: NetworkTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NetworkTargetPriorityOffsetAdjuster: NetworkTargetModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: NetworkTarget, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class RoundingNetworkTargetAdjuster: NetworkTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: NetworkTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedNetworkTargetAdjuster: NetworkTargetModifier {
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

        func adjust(_ item: NetworkTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network target steps in order and keeps a trace of each.
    final class NetworkTargetEngine {
        var steps: [any NetworkTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkTarget) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any NetworkTargetModifier = steps[index]
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

        func evaluateAll(_ items: [NetworkTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkTargetEngine(_ flags: Kit.Flags.Registry) -> NetworkTargetEngine {
        return NetworkTargetEngine(
            steps: [
                CapNetworkTargetAdjuster(cap: 14273.0),
                TieredNetworkTargetAdjuster(bounds: [5250.0, 8215.0, 9642.0], rates: [0.91, 0.92, 0.86]),
                NetworkTargetPriorityOffsetAdjuster(weight: 0.58),
                RoundingNetworkTargetAdjuster(step: 0.1),
                FlaggedNetworkTargetAdjuster(flags: flags, flag: "network-target-adaptive", percent: 4.5),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 67077.1
        )
    }
}
