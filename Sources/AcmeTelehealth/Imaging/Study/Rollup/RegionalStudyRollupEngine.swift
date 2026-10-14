import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional study rollup calculation.
    protocol RegionalStudyRollupStep {
        func describe() -> String
        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double
    }

    final class PercentRegionalStudyRollupAdjuster: RegionalStudyRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionRegionalStudyRollupAdjuster: RegionalStudyRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingRegionalStudyRollupAdjuster: RegionalStudyRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionalStudyRollupCeilingOffsetAdjuster: RegionalStudyRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedRegionalStudyRollupAdjuster: RegionalStudyRollupStep {
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

        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalStudyRollupAdjuster: RegionalStudyRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalStudyRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional study rollup steps in order and keeps a trace of each.
    final class RegionalStudyRollupEngine {
        var steps: [any RegionalStudyRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStudyRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalStudyRollup) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [RegionalStudyRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalStudyRollupEngine(_ flags: Kit.Flags.Registry) -> RegionalStudyRollupEngine {
        return RegionalStudyRollupEngine(
            steps: [
                PercentRegionalStudyRollupAdjuster(percent: -12.5),
                RegionRegionalStudyRollupAdjuster(factors: ["west": 0.88, "retail": 1.39]),
                RoundingRegionalStudyRollupAdjuster(step: 1.0),
                RegionalStudyRollupCeilingOffsetAdjuster(weight: 0.71),
                FlaggedRegionalStudyRollupAdjuster(flags: flags, flag: "regional-study-rollup-rolling", percent: -1.5),
                TieredRegionalStudyRollupAdjuster(
                    bounds: [1246.0, 5785.0, 9298.0, 9749.0],
                    rates: [1.07, 0.92, 1.18, 0.98]
                ),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 65488.4
        )
    }
}
