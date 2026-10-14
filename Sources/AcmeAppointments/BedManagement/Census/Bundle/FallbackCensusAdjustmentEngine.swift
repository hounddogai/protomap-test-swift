import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the fallback census adjustment calculation.
    protocol FallbackCensusAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackCensusAdjustment, value: Double) -> Double
    }

    final class TieredFallbackCensusAdjustmentAdjuster: FallbackCensusAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackCensusAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentFallbackCensusAdjustmentAdjuster: FallbackCensusAdjustmentAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackCensusAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackCensusAdjustmentAdjuster: FallbackCensusAdjustmentAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackCensusAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedFallbackCensusAdjustmentAdjuster: FallbackCensusAdjustmentAdjuster {
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

        func adjust(_ item: FallbackCensusAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the fallback census adjustment steps in order and keeps a trace of each.
    final class FallbackCensusAdjustmentEngine {
        var steps: [any FallbackCensusAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackCensusAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackCensusAdjustment) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackCensusAdjustmentAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackCensusAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackCensusAdjustmentEngine(_ flags: Kit.Flags.Registry) -> FallbackCensusAdjustmentEngine {
        return FallbackCensusAdjustmentEngine(
            steps: [
                TieredFallbackCensusAdjustmentAdjuster(
                    bounds: [911.0, 1889.0, 4524.0, 7582.0],
                    rates: [1.06, 0.81, 0.96, 0.87]
                ),
                PercentFallbackCensusAdjustmentAdjuster(percent: 21.9),
                RoundingFallbackCensusAdjustmentAdjuster(step: 0.25),
                FlaggedFallbackCensusAdjustmentAdjuster(
                    flags: flags,
                    flag: "fallback-census-adjustment-weighted",
                    percent: 7.4
                ),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 56518.1
        )
    }
}
