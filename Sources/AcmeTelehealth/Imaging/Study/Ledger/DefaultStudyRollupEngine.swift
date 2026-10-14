import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the default study rollup calculation.
    protocol DefaultStudyRollupModifier {
        func describe() -> String
        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double
    }

    final class CapDefaultStudyRollupAdjuster: DefaultStudyRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDefaultStudyRollupAdjuster: DefaultStudyRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitDefaultStudyRollupAdjuster: DefaultStudyRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDefaultStudyRollupAdjuster: DefaultStudyRollupModifier {
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

        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class DefaultStudyRollupRatioOffsetAdjuster: DefaultStudyRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class TieredDefaultStudyRollupAdjuster: DefaultStudyRollupModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DefaultStudyRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the default study rollup steps in order and keeps a trace of each.
    final class DefaultStudyRollupEngine {
        var steps: [any DefaultStudyRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultStudyRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DefaultStudyRollup) -> Double {
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

        func evaluateAll(_ items: [DefaultStudyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDefaultStudyRollupEngine(_ flags: Kit.Flags.Registry) -> DefaultStudyRollupEngine {
        return DefaultStudyRollupEngine(
            steps: [
                CapDefaultStudyRollupAdjuster(cap: 36276.0),
                PercentDefaultStudyRollupAdjuster(percent: -0.4),
                UnitDefaultStudyRollupAdjuster(factors: ["online": 1.01, "south": 1.22, "north": 1.04]),
                FlaggedDefaultStudyRollupAdjuster(flags: flags, flag: "default-study-rollup-seasonal", percent: -1.2),
                DefaultStudyRollupRatioOffsetAdjuster(weight: 0.79),
                TieredDefaultStudyRollupAdjuster(
                    bounds: [3854.0, 6023.0, 8143.0, 9625.0],
                    rates: [1.07, 1.08, 1.14, 0.95]
                ),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 39656.1
        )
    }
}
