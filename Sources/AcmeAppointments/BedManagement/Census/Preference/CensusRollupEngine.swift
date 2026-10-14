import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census rollup calculation.
    protocol CensusRollupStep {
        func describe() -> String
        func adjust(_ item: CensusRollup, value: Double) -> Double
    }

    final class TieredCensusRollupAdjuster: CensusRollupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCensusRollupAdjuster: CensusRollupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CensusRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedCensusRollupAdjuster: CensusRollupStep {
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

        func adjust(_ item: CensusRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumCensusRollupAdjuster: CensusRollupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CensusRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FacilityCensusRollupAdjuster: CensusRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: CensusRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCensusRollupAdjuster: CensusRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CensusRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the census rollup steps in order and keeps a trace of each.
    final class CensusRollupEngine {
        var steps: [any CensusRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CensusRollup) -> Double {
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

        func evaluateAll(_ items: [CensusRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCensusRollupEngine(_ flags: Kit.Flags.Registry) -> CensusRollupEngine {
        return CensusRollupEngine(
            steps: [
                TieredCensusRollupAdjuster(bounds: [168.0, 1726.0, 4432.0, 7140.0], rates: [0.88, 1.14, 0.93, 1.16]),
                RoundingCensusRollupAdjuster(step: 0.5),
                FlaggedCensusRollupAdjuster(flags: flags, flag: "census-rollup-strict", percent: -4.3),
                MinimumCensusRollupAdjuster(minimum: 32.2),
                FacilityCensusRollupAdjuster(factors: ["online": 0.87]),
                CapCensusRollupAdjuster(cap: 36459.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 5439.1
        )
    }
}
