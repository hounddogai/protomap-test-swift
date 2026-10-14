import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the adaptive denial variance calculation.
    protocol AdaptiveDenialVarianceAdjuster {
        func describe() -> String
        func adjust(_ item: AdaptiveDenialVariance, value: Double) -> Double
    }

    final class AdaptiveDenialVarianceRetriesOffsetAdjuster: AdaptiveDenialVarianceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: AdaptiveDenialVariance, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class MinimumAdaptiveDenialVarianceAdjuster: AdaptiveDenialVarianceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveDenialVariance, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveDenialVarianceAdjuster: AdaptiveDenialVarianceAdjuster {
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

        func adjust(_ item: AdaptiveDenialVariance, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingAdaptiveDenialVarianceAdjuster: AdaptiveDenialVarianceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveDenialVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredAdaptiveDenialVarianceAdjuster: AdaptiveDenialVarianceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveDenialVariance, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive denial variance steps in order and keeps a trace of each.
    final class AdaptiveDenialVarianceEngine {
        var steps: [any AdaptiveDenialVarianceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveDenialVarianceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AdaptiveDenialVariance) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AdaptiveDenialVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAdaptiveDenialVarianceEngine(_ flags: Kit.Flags.Registry) -> AdaptiveDenialVarianceEngine {
        return AdaptiveDenialVarianceEngine(
            steps: [
                AdaptiveDenialVarianceRetriesOffsetAdjuster(weight: 0.07),
                MinimumAdaptiveDenialVarianceAdjuster(minimum: 13.5),
                FlaggedAdaptiveDenialVarianceAdjuster(
                    flags: flags,
                    flag: "adaptive-denial-variance-manual",
                    percent: 3.5
                ),
                RoundingAdaptiveDenialVarianceAdjuster(step: 0.25),
                TieredAdaptiveDenialVarianceAdjuster(bounds: [327.0, 8296.0], rates: [0.88, 0.96]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 91719.0
        )
    }
}
