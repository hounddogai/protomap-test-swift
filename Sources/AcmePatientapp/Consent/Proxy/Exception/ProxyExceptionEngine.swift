import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy exception calculation.
    protocol ProxyExceptionFactor {
        func describe() -> String
        func adjust(_ item: ProxyException, value: Double) -> Double
    }

    final class TieredProxyExceptionAdjuster: ProxyExceptionFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ProxyException, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapProxyExceptionAdjuster: ProxyExceptionFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyException, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ProxyExceptionPriorityOffsetAdjuster: ProxyExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ProxyException, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class MinimumProxyExceptionAdjuster: ProxyExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedProxyExceptionAdjuster: ProxyExceptionFactor {
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

        func adjust(_ item: ProxyException, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyExceptionAdjuster: ProxyExceptionFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyException, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the proxy exception steps in order and keeps a trace of each.
    final class ProxyExceptionEngine {
        var steps: [any ProxyExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyException) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [ProxyException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyExceptionEngine(_ flags: Kit.Flags.Registry) -> ProxyExceptionEngine {
        return ProxyExceptionEngine(
            steps: [
                TieredProxyExceptionAdjuster(
                    bounds: [1166.0, 7303.0, 8839.0, 9640.0],
                    rates: [1.18, 0.97, 1.03, 0.98]
                ),
                CapProxyExceptionAdjuster(cap: 15572.0),
                ProxyExceptionPriorityOffsetAdjuster(weight: 0.3),
                MinimumProxyExceptionAdjuster(minimum: 36.4),
                FlaggedProxyExceptionAdjuster(flags: flags, flag: "proxy-exception-manual", percent: 4.7),
                RoundingProxyExceptionAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 54635.0
        )
    }
}
