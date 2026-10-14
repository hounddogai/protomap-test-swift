import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form rollup calculation.
    protocol ConsentFormRollupFactor {
        func describe() -> String
        func adjust(_ item: ConsentFormRollup, value: Double) -> Double
    }

    final class TieredConsentFormRollupAdjuster: ConsentFormRollupFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormRollup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedConsentFormRollupAdjuster: ConsentFormRollupFactor {
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

        func adjust(_ item: ConsentFormRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumConsentFormRollupAdjuster: ConsentFormRollupFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormRollup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapConsentFormRollupAdjuster: ConsentFormRollupFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ConsentFormRollupGraceDaysOffsetAdjuster: ConsentFormRollupFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: ConsentFormRollup, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class RoundingConsentFormRollupAdjuster: ConsentFormRollupFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form rollup steps in order and keeps a trace of each.
    final class ConsentFormRollupEngine {
        var steps: [any ConsentFormRollupFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormRollupFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ConsentFormRollup) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ConsentFormRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultConsentFormRollupEngine(_ flags: Kit.Flags.Registry) -> ConsentFormRollupEngine {
        return ConsentFormRollupEngine(
            steps: [
                TieredConsentFormRollupAdjuster(bounds: [4714.0, 6162.0], rates: [0.95, 1.07]),
                FlaggedConsentFormRollupAdjuster(flags: flags, flag: "consent-form-rollup-batched", percent: -8.3),
                MinimumConsentFormRollupAdjuster(minimum: 17.7),
                CapConsentFormRollupAdjuster(cap: 25153.0),
                ConsentFormRollupGraceDaysOffsetAdjuster(weight: 1.73),
                RoundingConsentFormRollupAdjuster(step: 5.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 17195.6
        )
    }
}
