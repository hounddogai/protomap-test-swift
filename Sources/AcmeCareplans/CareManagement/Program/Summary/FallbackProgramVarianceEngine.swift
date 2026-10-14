import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback program variance calculation.
    protocol FallbackProgramVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackProgramVariance, value: Double) -> Double
    }

    final class FlaggedFallbackProgramVarianceAdjuster: FallbackProgramVarianceAdjuster {
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

        func adjust(_ item: FallbackProgramVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingFallbackProgramVarianceAdjuster: FallbackProgramVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackProgramVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackProgramVarianceAdjuster: FallbackProgramVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackProgramVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback program variance steps in order and keeps a trace of each.
    final class FallbackProgramVarianceEngine {
        var steps: [any FallbackProgramVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackProgramVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackProgramVariance) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FallbackProgramVarianceAdjuster = steps[index]
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

        func evaluateAll(_ items: [FallbackProgramVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackProgramVarianceEngine(_ flags: Kit.Flags.Registry) -> FallbackProgramVarianceEngine {
        return FallbackProgramVarianceEngine(
            steps: [
                FlaggedFallbackProgramVarianceAdjuster(
                    flags: flags,
                    flag: "fallback-program-variance-manual",
                    percent: -6.1
                ),
                RoundingFallbackProgramVarianceAdjuster(step: 0.1),
                TieredFallbackProgramVarianceAdjuster(bounds: [2402.0, 5882.0, 6396.0], rates: [0.81, 1.02, 0.94]),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 3329.9
        )
    }
}
