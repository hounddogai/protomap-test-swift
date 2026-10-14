import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the default network window calculation.
    protocol DefaultNetworkWindowAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultNetworkWindow, value: Double) -> Double
    }

    final class LabelDefaultNetworkWindowAdjuster: DefaultNetworkWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultNetworkWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultNetworkWindowAdjuster: DefaultNetworkWindowAdjuster {
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

        func adjust(_ item: DefaultNetworkWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentDefaultNetworkWindowAdjuster: DefaultNetworkWindowAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultNetworkWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDefaultNetworkWindowAdjuster: DefaultNetworkWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultNetworkWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default network window steps in order and keeps a trace of each.
    final class DefaultNetworkWindowEngine {
        var steps: [any DefaultNetworkWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultNetworkWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DefaultNetworkWindow) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [DefaultNetworkWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDefaultNetworkWindowEngine(_ flags: Kit.Flags.Registry) -> DefaultNetworkWindowEngine {
        return DefaultNetworkWindowEngine(
            steps: [
                LabelDefaultNetworkWindowAdjuster(factors: ["central": 0.85, "west": 1.2]),
                FlaggedDefaultNetworkWindowAdjuster(
                    flags: flags,
                    flag: "default-network-window-lenient",
                    percent: 0.8
                ),
                PercentDefaultNetworkWindowAdjuster(percent: -14.0),
                TieredDefaultNetworkWindowAdjuster(bounds: [7457.0, 9066.0], rates: [1.0, 0.99]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 44901.2
        )
    }
}
