import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial quota calculation.
    protocol DenialQuotaStep {
        func describe() -> String
        func adjust(_ item: DenialQuota, value: Double) -> Double
    }

    final class PercentDenialQuotaAdjuster: DenialQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDenialQuotaAdjuster: DenialQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DenialQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingDenialQuotaAdjuster: DenialQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DenialQuotaScoreOffsetAdjuster: DenialQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: DenialQuota, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedDenialQuotaAdjuster: DenialQuotaStep {
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

        func adjust(_ item: DenialQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDenialQuotaAdjuster: DenialQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the denial quota steps in order and keeps a trace of each.
    final class DenialQuotaEngine {
        var steps: [any DenialQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DenialQuota) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialQuotaStep = steps[index]
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

        func evaluateAll(_ items: [DenialQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDenialQuotaEngine(_ flags: Kit.Flags.Registry) -> DenialQuotaEngine {
        return DenialQuotaEngine(
            steps: [
                PercentDenialQuotaAdjuster(percent: -4.0),
                TieredDenialQuotaAdjuster(bounds: [3388.0, 4825.0], rates: [0.94, 0.82]),
                RoundingDenialQuotaAdjuster(step: 0.1),
                DenialQuotaScoreOffsetAdjuster(weight: 0.92),
                FlaggedDenialQuotaAdjuster(flags: flags, flag: "denial-quota-legacy", percent: -1.7),
                MinimumDenialQuotaAdjuster(minimum: 40.2),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 18511.5
        )
    }
}
