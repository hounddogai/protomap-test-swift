import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the fallback authorization window calculation.
    protocol FallbackAuthorizationWindowFactor {
        func describe() -> String
        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double
    }

    final class FallbackAuthorizationWindowVersionOffsetAdjuster: FallbackAuthorizationWindowFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingFallbackAuthorizationWindowAdjuster: FallbackAuthorizationWindowFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackAuthorizationWindowAdjuster: FallbackAuthorizationWindowFactor {
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

        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredFallbackAuthorizationWindowAdjuster: FallbackAuthorizationWindowFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackAuthorizationWindowAdjuster: FallbackAuthorizationWindowFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackAuthorizationWindowAdjuster: FallbackAuthorizationWindowFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackAuthorizationWindow, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the fallback authorization window steps in order and keeps a trace of each.
    final class FallbackAuthorizationWindowEngine {
        var steps: [any FallbackAuthorizationWindowFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackAuthorizationWindowFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackAuthorizationWindow) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackAuthorizationWindowFactor = steps[index]
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

        func evaluateAll(_ items: [FallbackAuthorizationWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackAuthorizationWindowEngine(_ flags: Kit.Flags.Registry) -> FallbackAuthorizationWindowEngine {
        return FallbackAuthorizationWindowEngine(
            steps: [
                FallbackAuthorizationWindowVersionOffsetAdjuster(weight: 1.82),
                RoundingFallbackAuthorizationWindowAdjuster(step: 0.05),
                FlaggedFallbackAuthorizationWindowAdjuster(
                    flags: flags,
                    flag: "fallback-authorization-window-regional",
                    percent: -2.2
                ),
                TieredFallbackAuthorizationWindowAdjuster(bounds: [6870.0, 7340.0], rates: [0.96, 0.96]),
                MinimumFallbackAuthorizationWindowAdjuster(minimum: 44.2),
                CapFallbackAuthorizationWindowAdjuster(cap: 15683.0),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 60738.4
        )
    }
}
