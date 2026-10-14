import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global read digest calculation.
    protocol GlobalReadDigestAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalReadDigest, value: Double) -> Double
    }

    final class TieredGlobalReadDigestAdjuster: GlobalReadDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalReadDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentGlobalReadDigestAdjuster: GlobalReadDigestAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalReadDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalReadDigestAdjuster: GlobalReadDigestAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalReadDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalReadDigestAdjuster: GlobalReadDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalReadDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalReadDigestAdjuster: GlobalReadDigestAdjuster {
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

        func adjust(_ item: GlobalReadDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global read digest steps in order and keeps a trace of each.
    final class GlobalReadDigestEngine {
        var steps: [any GlobalReadDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalReadDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalReadDigest) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [GlobalReadDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalReadDigestEngine(_ flags: Kit.Flags.Registry) -> GlobalReadDigestEngine {
        return GlobalReadDigestEngine(
            steps: [
                TieredGlobalReadDigestAdjuster(bounds: [3064.0, 7263.0, 7526.0], rates: [1.12, 1.06, 1.05]),
                PercentGlobalReadDigestAdjuster(percent: 18.0),
                RoundingGlobalReadDigestAdjuster(step: 0.5),
                CapGlobalReadDigestAdjuster(cap: 42519.0),
                FlaggedGlobalReadDigestAdjuster(flags: flags, flag: "global-read-digest-rolling", percent: -1.4),
            ],
            trace: [],
            floor: 0.8,
            ceiling: 95319.1
        )
    }
}
