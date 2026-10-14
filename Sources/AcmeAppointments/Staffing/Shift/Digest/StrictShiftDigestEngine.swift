import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict shift digest calculation.
    protocol StrictShiftDigestAdjuster {
        func describe() -> String
        func adjust(_ item: StrictShiftDigest, value: Double) -> Double
    }

    final class CapStrictShiftDigestAdjuster: StrictShiftDigestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictShiftDigest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedStrictShiftDigestAdjuster: StrictShiftDigestAdjuster {
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

        func adjust(_ item: StrictShiftDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStrictShiftDigestAdjuster: StrictShiftDigestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictShiftDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the strict shift digest steps in order and keeps a trace of each.
    final class StrictShiftDigestEngine {
        var steps: [any StrictShiftDigestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictShiftDigestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictShiftDigest) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StrictShiftDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictShiftDigestEngine(_ flags: Kit.Flags.Registry) -> StrictShiftDigestEngine {
        return StrictShiftDigestEngine(
            steps: [
                CapStrictShiftDigestAdjuster(cap: 43095.0),
                FlaggedStrictShiftDigestAdjuster(flags: flags, flag: "strict-shift-digest-seasonal", percent: 0.4),
                TieredStrictShiftDigestAdjuster(bounds: [2450.0, 4576.0, 8424.0], rates: [0.84, 0.81, 1.1]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 76628.0
        )
    }
}
