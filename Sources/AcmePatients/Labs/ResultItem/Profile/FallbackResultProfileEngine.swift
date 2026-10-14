import AcmePlatform
import Foundation

extension Labs {
    /// One step of the fallback result profile calculation.
    protocol FallbackResultProfileAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackResultProfile, value: Double) -> Double
    }

    final class CapFallbackResultProfileAdjuster: FallbackResultProfileAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackResultProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedFallbackResultProfileAdjuster: FallbackResultProfileAdjuster {
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

        func adjust(_ item: FallbackResultProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentFallbackResultProfileAdjuster: FallbackResultProfileAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackResultProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FallbackResultProfileCostOffsetAdjuster: FallbackResultProfileAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: FallbackResultProfile, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class TieredFallbackResultProfileAdjuster: FallbackResultProfileAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackResultProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumFallbackResultProfileAdjuster: FallbackResultProfileAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackResultProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the fallback result profile steps in order and keeps a trace of each.
    final class FallbackResultProfileEngine {
        var steps: [any FallbackResultProfileAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackResultProfileAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackResultProfile) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [FallbackResultProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackResultProfileEngine(_ flags: Kit.Flags.Registry) -> FallbackResultProfileEngine {
        return FallbackResultProfileEngine(
            steps: [
                CapFallbackResultProfileAdjuster(cap: 49849.0),
                FlaggedFallbackResultProfileAdjuster(
                    flags: flags,
                    flag: "fallback-result-profile-global",
                    percent: -8.9
                ),
                PercentFallbackResultProfileAdjuster(percent: 17.6),
                FallbackResultProfileCostOffsetAdjuster(weight: 1.74),
                TieredFallbackResultProfileAdjuster(bounds: [4184.0, 6126.0, 9490.0], rates: [0.98, 0.83, 1.1]),
                MinimumFallbackResultProfileAdjuster(minimum: 4.3),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 90535.5
        )
    }
}
