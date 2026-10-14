import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist rollup calculation.
    protocol WorklistRollupFactor {
        func describe() -> String
        func adjust(_ item: WorklistRollup, value: Double) -> Double
    }

    final class WorklistRollupAcuityOffsetAdjuster: WorklistRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: WorklistRollup, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class MinimumWorklistRollupAdjuster: WorklistRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CountryWorklistRollupAdjuster: WorklistRollupFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: WorklistRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedWorklistRollupAdjuster: WorklistRollupFactor {
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

        func adjust(_ item: WorklistRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredWorklistRollupAdjuster: WorklistRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WorklistRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWorklistRollupAdjuster: WorklistRollupFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the worklist rollup steps in order and keeps a trace of each.
    final class WorklistRollupEngine {
        var steps: [any WorklistRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistRollup) -> Double {
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

        func evaluateAll(_ items: [WorklistRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistRollupEngine(_ flags: Kit.Flags.Registry) -> WorklistRollupEngine {
        return WorklistRollupEngine(
            steps: [
                WorklistRollupAcuityOffsetAdjuster(weight: 1.11),
                MinimumWorklistRollupAdjuster(minimum: 46.0),
                CountryWorklistRollupAdjuster(factors: ["south": 0.72, "east": 0.96]),
                FlaggedWorklistRollupAdjuster(flags: flags, flag: "worklist-rollup-regional", percent: -5.4),
                TieredWorklistRollupAdjuster(
                    bounds: [4887.0, 6226.0, 7248.0, 9270.0],
                    rates: [0.84, 0.85, 1.05, 0.91]
                ),
                PercentWorklistRollupAdjuster(percent: -7.6),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 69686.1
        )
    }
}
