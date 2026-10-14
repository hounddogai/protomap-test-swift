import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the global rounding claim calculation.
    protocol GlobalRoundingClaimFactor {
        func describe() -> String
        func adjust(_ item: GlobalRoundingClaim, value: Double) -> Double
    }

    final class RoundingGlobalRoundingClaimAdjuster: GlobalRoundingClaimFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalRoundingClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalRoundingClaimAdjuster: GlobalRoundingClaimFactor {
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

        func adjust(_ item: GlobalRoundingClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelGlobalRoundingClaimAdjuster: GlobalRoundingClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: GlobalRoundingClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalRoundingClaimAdjuster: GlobalRoundingClaimFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalRoundingClaim, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalRoundingClaimAdjuster: GlobalRoundingClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalRoundingClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the global rounding claim steps in order and keeps a trace of each.
    final class GlobalRoundingClaimEngine {
        var steps: [any GlobalRoundingClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRoundingClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalRoundingClaim) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [GlobalRoundingClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalRoundingClaimEngine(_ flags: Kit.Flags.Registry) -> GlobalRoundingClaimEngine {
        return GlobalRoundingClaimEngine(
            steps: [
                RoundingGlobalRoundingClaimAdjuster(step: 5.0),
                FlaggedGlobalRoundingClaimAdjuster(flags: flags, flag: "global-rounding-claim-fallback", percent: 5.3),
                LabelGlobalRoundingClaimAdjuster(factors: ["east": 1.25]),
                PercentGlobalRoundingClaimAdjuster(percent: 15.8),
                TieredGlobalRoundingClaimAdjuster(bounds: [211.0, 4776.0, 8486.0], rates: [1.18, 0.86, 0.91]),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 76015.8
        )
    }
}
