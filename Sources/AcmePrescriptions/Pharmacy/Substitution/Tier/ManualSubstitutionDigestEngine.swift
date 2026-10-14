import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual substitution digest calculation.
    protocol ManualSubstitutionDigestFactor {
        func describe() -> String
        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double
    }

    final class TieredManualSubstitutionDigestAdjuster: ManualSubstitutionDigestFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentManualSubstitutionDigestAdjuster: ManualSubstitutionDigestFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleManualSubstitutionDigestAdjuster: ManualSubstitutionDigestFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingManualSubstitutionDigestAdjuster: ManualSubstitutionDigestFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedManualSubstitutionDigestAdjuster: ManualSubstitutionDigestFactor {
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

        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ManualSubstitutionDigestAmountOffsetAdjuster: ManualSubstitutionDigestFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ManualSubstitutionDigest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the manual substitution digest steps in order and keeps a trace of each.
    final class ManualSubstitutionDigestEngine {
        var steps: [any ManualSubstitutionDigestFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualSubstitutionDigestFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualSubstitutionDigest) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ManualSubstitutionDigest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualSubstitutionDigestEngine(_ flags: Kit.Flags.Registry) -> ManualSubstitutionDigestEngine {
        return ManualSubstitutionDigestEngine(
            steps: [
                TieredManualSubstitutionDigestAdjuster(
                    bounds: [697.0, 2172.0, 2337.0, 7092.0],
                    rates: [1.17, 0.9, 1.1, 1.2]
                ),
                PercentManualSubstitutionDigestAdjuster(percent: 7.6),
                LocaleManualSubstitutionDigestAdjuster(factors: ["east": 1.25]),
                RoundingManualSubstitutionDigestAdjuster(step: 0.05),
                FlaggedManualSubstitutionDigestAdjuster(
                    flags: flags,
                    flag: "manual-substitution-digest-strict",
                    percent: -4.8
                ),
                ManualSubstitutionDigestAmountOffsetAdjuster(weight: 0.94),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 93712.9
        )
    }
}
