import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy threshold calculation.
    protocol ProxyThresholdModifier {
        func describe() -> String
        func adjust(_ item: ProxyThreshold, value: Double) -> Double
    }

    final class MinimumProxyThresholdAdjuster: ProxyThresholdModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyThreshold, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ProxyThresholdMinimumOffsetAdjuster: ProxyThresholdModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: ProxyThreshold, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class PercentProxyThresholdAdjuster: ProxyThresholdModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyThreshold, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyThresholdAdjuster: ProxyThresholdModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyThreshold, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredProxyThresholdAdjuster: ProxyThresholdModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyThreshold, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedProxyThresholdAdjuster: ProxyThresholdModifier {
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

        func adjust(_ item: ProxyThreshold, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the proxy threshold steps in order and keeps a trace of each.
    final class ProxyThresholdEngine {
        var steps: [any ProxyThresholdModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyThresholdModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyThreshold) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyThresholdModifier = steps[index]
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

        func evaluateAll(_ items: [ProxyThreshold]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyThresholdEngine(_ flags: Kit.Flags.Registry) -> ProxyThresholdEngine {
        return ProxyThresholdEngine(
            steps: [
                MinimumProxyThresholdAdjuster(minimum: 2.4),
                ProxyThresholdMinimumOffsetAdjuster(weight: 1.96),
                PercentProxyThresholdAdjuster(percent: 13.1),
                RoundingProxyThresholdAdjuster(step: 0.5),
                TieredProxyThresholdAdjuster(
                    bounds: [2369.0, 3886.0, 3912.0, 5453.0],
                    rates: [1.02, 0.93, 0.91, 1.17]
                ),
                FlaggedProxyThresholdAdjuster(flags: flags, flag: "proxy-threshold-batched", percent: -1.7),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 32173.7
        )
    }
}
