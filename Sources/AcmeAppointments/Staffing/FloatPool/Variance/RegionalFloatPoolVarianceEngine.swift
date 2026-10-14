import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional float pool variance calculation.
    protocol RegionalFloatPoolVarianceStep {
        func describe() -> String
        func adjust(_ item: RegionalFloatPoolVariance, value: Double) -> Double
    }

    final class MinimumRegionalFloatPoolVarianceAdjuster: RegionalFloatPoolVarianceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalFloatPoolVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedRegionalFloatPoolVarianceAdjuster: RegionalFloatPoolVarianceStep {
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

        func adjust(_ item: RegionalFloatPoolVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredRegionalFloatPoolVarianceAdjuster: RegionalFloatPoolVarianceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalFloatPoolVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the regional float pool variance steps in order and keeps a trace of each.
    final class RegionalFloatPoolVarianceEngine {
        var steps: [any RegionalFloatPoolVarianceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFloatPoolVarianceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalFloatPoolVariance) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalFloatPoolVarianceStep = steps[index]
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

        func evaluateAll(_ items: [RegionalFloatPoolVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalFloatPoolVarianceEngine(_ flags: Kit.Flags.Registry) -> RegionalFloatPoolVarianceEngine {
        return RegionalFloatPoolVarianceEngine(
            steps: [
                MinimumRegionalFloatPoolVarianceAdjuster(minimum: 16.3),
                FlaggedRegionalFloatPoolVarianceAdjuster(
                    flags: flags,
                    flag: "regional-float-pool-variance-primary",
                    percent: -7.8
                ),
                TieredRegionalFloatPoolVarianceAdjuster(
                    bounds: [1807.0, 3219.0, 4133.0, 6970.0],
                    rates: [0.86, 1.15, 1.12, 0.84]
                ),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 39064.0
        )
    }
}
