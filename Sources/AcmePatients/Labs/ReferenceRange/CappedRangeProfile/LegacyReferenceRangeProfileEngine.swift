import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy reference range profile calculation.
    protocol LegacyReferenceRangeProfileStep {
        func describe() -> String
        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double
    }

    final class CapLegacyReferenceRangeProfileAdjuster: LegacyReferenceRangeProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacyReferenceRangeProfileRetriesOffsetAdjuster: LegacyReferenceRangeProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class RoundingLegacyReferenceRangeProfileAdjuster: LegacyReferenceRangeProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedLegacyReferenceRangeProfileAdjuster: LegacyReferenceRangeProfileStep {
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

        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredLegacyReferenceRangeProfileAdjuster: LegacyReferenceRangeProfileStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class LabelLegacyReferenceRangeProfileAdjuster: LegacyReferenceRangeProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacyReferenceRangeProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the legacy reference range profile steps in order and keeps a trace of each.
    final class LegacyReferenceRangeProfileEngine {
        var steps: [any LegacyReferenceRangeProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacyReferenceRangeProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LegacyReferenceRangeProfile) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [LegacyReferenceRangeProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLegacyReferenceRangeProfileEngine(_ flags: Kit.Flags.Registry) -> LegacyReferenceRangeProfileEngine {
        return LegacyReferenceRangeProfileEngine(
            steps: [
                CapLegacyReferenceRangeProfileAdjuster(cap: 15509.0),
                LegacyReferenceRangeProfileRetriesOffsetAdjuster(weight: 1.66),
                RoundingLegacyReferenceRangeProfileAdjuster(step: 0.05),
                FlaggedLegacyReferenceRangeProfileAdjuster(
                    flags: flags,
                    flag: "legacy-reference-range-profile-rolling",
                    percent: 0.1
                ),
                TieredLegacyReferenceRangeProfileAdjuster(bounds: [452.0, 4227.0, 6107.0], rates: [1.04, 1.07, 1.17]),
                LabelLegacyReferenceRangeProfileAdjuster(factors: ["south": 1.07, "online": 0.93]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 40230.6
        )
    }
}
