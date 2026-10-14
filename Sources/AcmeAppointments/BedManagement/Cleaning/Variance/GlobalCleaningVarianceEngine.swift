import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the global cleaning variance calculation.
    protocol GlobalCleaningVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double
    }

    final class PercentGlobalCleaningVarianceAdjuster: GlobalCleaningVarianceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalCleaningVarianceAdjuster: GlobalCleaningVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapGlobalCleaningVarianceAdjuster: GlobalCleaningVarianceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CountryGlobalCleaningVarianceAdjuster: GlobalCleaningVarianceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredGlobalCleaningVarianceAdjuster: GlobalCleaningVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedGlobalCleaningVarianceAdjuster: GlobalCleaningVarianceAdjuster {
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

        func adjust(_ item: GlobalCleaningVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global cleaning variance steps in order and keeps a trace of each.
    final class GlobalCleaningVarianceEngine {
        var steps: [any GlobalCleaningVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCleaningVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalCleaningVariance) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCleaningVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalCleaningVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalCleaningVarianceEngine(_ flags: Kit.Flags.Registry) -> GlobalCleaningVarianceEngine {
        return GlobalCleaningVarianceEngine(
            steps: [
                PercentGlobalCleaningVarianceAdjuster(percent: -8.8),
                RoundingGlobalCleaningVarianceAdjuster(step: 0.25),
                CapGlobalCleaningVarianceAdjuster(cap: 8797.0),
                CountryGlobalCleaningVarianceAdjuster(factors: ["central": 1.22]),
                TieredGlobalCleaningVarianceAdjuster(
                    bounds: [773.0, 1840.0, 1855.0, 8069.0],
                    rates: [1.13, 0.81, 1.1, 1.04]
                ),
                FlaggedGlobalCleaningVarianceAdjuster(
                    flags: flags,
                    flag: "global-cleaning-variance-batched",
                    percent: -6.8
                ),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 18146.1
        )
    }
}
