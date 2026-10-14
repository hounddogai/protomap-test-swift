import AcmePlatform
import Foundation

extension Consent {
    /// One step of the fallback disclosure profile calculation.
    protocol FallbackDisclosureProfileFactor {
        func describe() -> String
        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double
    }

    final class FallbackDisclosureProfileDiscountOffsetAdjuster: FallbackDisclosureProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus discount times \(weight)"
        }

        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double {
            return value + item.discount * weight
        }
    }

    final class PercentFallbackDisclosureProfileAdjuster: FallbackDisclosureProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedFallbackDisclosureProfileAdjuster: FallbackDisclosureProfileFactor {
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

        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumFallbackDisclosureProfileAdjuster: FallbackDisclosureProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFallbackDisclosureProfileAdjuster: FallbackDisclosureProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackDisclosureProfileAdjuster: FallbackDisclosureProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackDisclosureProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the fallback disclosure profile steps in order and keeps a trace of each.
    final class FallbackDisclosureProfileEngine {
        var steps: [any FallbackDisclosureProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackDisclosureProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackDisclosureProfile) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [FallbackDisclosureProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackDisclosureProfileEngine(_ flags: Kit.Flags.Registry) -> FallbackDisclosureProfileEngine {
        return FallbackDisclosureProfileEngine(
            steps: [
                FallbackDisclosureProfileDiscountOffsetAdjuster(weight: 1.96),
                PercentFallbackDisclosureProfileAdjuster(percent: -15.5),
                FlaggedFallbackDisclosureProfileAdjuster(
                    flags: flags,
                    flag: "fallback-disclosure-profile-global",
                    percent: -0.1
                ),
                MinimumFallbackDisclosureProfileAdjuster(minimum: 8.5),
                RoundingFallbackDisclosureProfileAdjuster(step: 0.1),
                TieredFallbackDisclosureProfileAdjuster(
                    bounds: [1517.0, 4766.0, 6353.0, 8319.0],
                    rates: [0.96, 0.9, 0.86, 0.85]
                ),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 41332.7
        )
    }
}
