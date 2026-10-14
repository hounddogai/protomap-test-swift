import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the eligibility baseline calculation.
    protocol EligibilityBaselineFactor {
        func describe() -> String
        func adjust(_ item: EligibilityBaseline, value: Double) -> Double
    }

    final class EligibilityBaselineBatchSizeOffsetAdjuster: EligibilityBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: EligibilityBaseline, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredEligibilityBaselineAdjuster: EligibilityBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: EligibilityBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapEligibilityBaselineAdjuster: EligibilityBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: EligibilityBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumEligibilityBaselineAdjuster: EligibilityBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: EligibilityBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedEligibilityBaselineAdjuster: EligibilityBaselineFactor {
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

        func adjust(_ item: EligibilityBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the eligibility baseline steps in order and keeps a trace of each.
    final class EligibilityBaselineEngine {
        var steps: [any EligibilityBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any EligibilityBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: EligibilityBaseline) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [EligibilityBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultEligibilityBaselineEngine(_ flags: Kit.Flags.Registry) -> EligibilityBaselineEngine {
        return EligibilityBaselineEngine(
            steps: [
                EligibilityBaselineBatchSizeOffsetAdjuster(weight: 0.39),
                TieredEligibilityBaselineAdjuster(bounds: [606.0, 1295.0, 4132.0], rates: [0.94, 0.82, 0.87]),
                CapEligibilityBaselineAdjuster(cap: 23838.0),
                MinimumEligibilityBaselineAdjuster(minimum: 38.0),
                FlaggedEligibilityBaselineAdjuster(flags: flags, flag: "eligibility-baseline-default", percent: 9.4),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 47125.0
        )
    }
}
