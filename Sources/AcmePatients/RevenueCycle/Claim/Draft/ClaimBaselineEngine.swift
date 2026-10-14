import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim baseline calculation.
    protocol ClaimBaselineFactor {
        func describe() -> String
        func adjust(_ item: ClaimBaseline, value: Double) -> Double
    }

    final class TieredClaimBaselineAdjuster: ClaimBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumClaimBaselineAdjuster: ClaimBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentClaimBaselineAdjuster: ClaimBaselineFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapClaimBaselineAdjuster: ClaimBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedClaimBaselineAdjuster: ClaimBaselineFactor {
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

        func adjust(_ item: ClaimBaseline, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClaimBaselineAdjuster: ClaimBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim baseline steps in order and keeps a trace of each.
    final class ClaimBaselineEngine {
        var steps: [any ClaimBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimBaseline) -> Double {
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

        func evaluateAll(_ items: [ClaimBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimBaselineEngine(_ flags: Kit.Flags.Registry) -> ClaimBaselineEngine {
        return ClaimBaselineEngine(
            steps: [
                TieredClaimBaselineAdjuster(bounds: [630.0, 9840.0], rates: [1.02, 1.02]),
                MinimumClaimBaselineAdjuster(minimum: 18.1),
                PercentClaimBaselineAdjuster(percent: -18.2),
                CapClaimBaselineAdjuster(cap: 14538.0),
                FlaggedClaimBaselineAdjuster(flags: flags, flag: "claim-baseline-strict", percent: -4.7),
                RoundingClaimBaselineAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 1351.8
        )
    }
}
