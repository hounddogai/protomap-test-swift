import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the legacy charge score calculation.
    protocol LegacyChargeScoreFactor {
        func describe() -> String
        func adjust(_ item: LegacyChargeScore, value: Double) -> Double
    }

    final class RoundingLegacyChargeScoreAdjuster: LegacyChargeScoreFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyChargeScore, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLegacyChargeScoreAdjuster: LegacyChargeScoreFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyChargeScore, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameLegacyChargeScoreAdjuster: LegacyChargeScoreFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LegacyChargeScore, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedLegacyChargeScoreAdjuster: LegacyChargeScoreFactor {
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

        func adjust(_ item: LegacyChargeScore, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyChargeScoreAdjuster: LegacyChargeScoreFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyChargeScore, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLegacyChargeScoreAdjuster: LegacyChargeScoreFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacyChargeScore, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the legacy charge score steps in order and keeps a trace of each.
    final class LegacyChargeScoreEngine {
        var steps: [any LegacyChargeScoreFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyChargeScoreFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LegacyChargeScore) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [LegacyChargeScore]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLegacyChargeScoreEngine(_ flags: Kit.Flags.Registry) -> LegacyChargeScoreEngine {
        return LegacyChargeScoreEngine(
            steps: [
                RoundingLegacyChargeScoreAdjuster(step: 0.05),
                CapLegacyChargeScoreAdjuster(cap: 44680.0),
                NameLegacyChargeScoreAdjuster(factors: ["online": 0.82, "south": 1.2]),
                FlaggedLegacyChargeScoreAdjuster(flags: flags, flag: "legacy-charge-score-adaptive", percent: 9.8),
                TieredLegacyChargeScoreAdjuster(bounds: [2789.0, 6575.0, 8422.0], rates: [1.03, 1.03, 1.17]),
                MinimumLegacyChargeScoreAdjuster(minimum: 15.7),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 35139.0
        )
    }
}
