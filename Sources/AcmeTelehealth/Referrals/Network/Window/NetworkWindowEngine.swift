import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the network window calculation.
    protocol NetworkWindowFactor {
        func describe() -> String
        func adjust(_ item: NetworkWindow, value: Double) -> Double
    }

    final class FlaggedNetworkWindowAdjuster: NetworkWindowFactor {
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

        func adjust(_ item: NetworkWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NetworkWindowCreatedAtOffsetAdjuster: NetworkWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: NetworkWindow, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class LocaleNetworkWindowAdjuster: NetworkWindowFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: NetworkWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentNetworkWindowAdjuster: NetworkWindowFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: NetworkWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the network window steps in order and keeps a trace of each.
    final class NetworkWindowEngine {
        var steps: [any NetworkWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any NetworkWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: NetworkWindow) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [NetworkWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultNetworkWindowEngine(_ flags: Kit.Flags.Registry) -> NetworkWindowEngine {
        return NetworkWindowEngine(
            steps: [
                FlaggedNetworkWindowAdjuster(flags: flags, flag: "network-window-adaptive", percent: -5.4),
                NetworkWindowCreatedAtOffsetAdjuster(weight: 1.67),
                LocaleNetworkWindowAdjuster(factors: ["online": 1.14]),
                PercentNetworkWindowAdjuster(percent: 5.1),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 4751.0
        )
    }
}
