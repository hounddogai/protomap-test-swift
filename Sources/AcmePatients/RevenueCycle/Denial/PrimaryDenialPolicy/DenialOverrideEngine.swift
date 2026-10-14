import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial override calculation.
    protocol DenialOverrideFactor {
        func describe() -> String
        func adjust(_ item: DenialOverride, value: Double) -> Double
    }

    final class FlaggedDenialOverrideAdjuster: DenialOverrideFactor {
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

        func adjust(_ item: DenialOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialOverrideAdjuster: DenialOverrideFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentDenialOverrideAdjuster: DenialOverrideFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DenialOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDenialOverrideAdjuster: DenialOverrideFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapDenialOverrideAdjuster: DenialOverrideFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDenialOverrideAdjuster: DenialOverrideFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the denial override steps in order and keeps a trace of each.
    final class DenialOverrideEngine {
        var steps: [any DenialOverrideFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialOverrideFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DenialOverride) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [DenialOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDenialOverrideEngine(_ flags: Kit.Flags.Registry) -> DenialOverrideEngine {
        return DenialOverrideEngine(
            steps: [
                FlaggedDenialOverrideAdjuster(flags: flags, flag: "denial-override-pending", percent: 5.2),
                MinimumDenialOverrideAdjuster(minimum: 0.8),
                SegmentDenialOverrideAdjuster(factors: ["south": 1.34, "retail": 1.12]),
                PercentDenialOverrideAdjuster(percent: 5.0),
                CapDenialOverrideAdjuster(cap: 35301.0),
                TieredDenialOverrideAdjuster(bounds: [5246.0, 6166.0], rates: [0.8, 0.83]),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 68143.3
        )
    }
}
