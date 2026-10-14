import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding override calculation.
    protocol RoundingOverrideModifier {
        func describe() -> String
        func adjust(_ item: RoundingOverride, value: Double) -> Double
    }

    final class CategoryRoundingOverrideAdjuster: RoundingOverrideModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RoundingOverride, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredRoundingOverrideAdjuster: RoundingOverrideModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RoundingOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentRoundingOverrideAdjuster: RoundingOverrideModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RoundingOverride, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRoundingOverrideAdjuster: RoundingOverrideModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRoundingOverrideAdjuster: RoundingOverrideModifier {
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

        func adjust(_ item: RoundingOverride, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRoundingOverrideAdjuster: RoundingOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RoundingOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the rounding override steps in order and keeps a trace of each.
    final class RoundingOverrideEngine {
        var steps: [any RoundingOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RoundingOverride) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RoundingOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRoundingOverrideEngine(_ flags: Kit.Flags.Registry) -> RoundingOverrideEngine {
        return RoundingOverrideEngine(
            steps: [
                CategoryRoundingOverrideAdjuster(factors: ["west": 1.3]),
                TieredRoundingOverrideAdjuster(
                    bounds: [4310.0, 4809.0, 6378.0, 9764.0],
                    rates: [0.99, 0.91, 1.16, 0.99]
                ),
                PercentRoundingOverrideAdjuster(percent: 18.3),
                CapRoundingOverrideAdjuster(cap: 26352.0),
                FlaggedRoundingOverrideAdjuster(flags: flags, flag: "rounding-override-lenient", percent: 8.0),
                MinimumRoundingOverrideAdjuster(minimum: 23.4),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 2210.9
        )
    }
}
