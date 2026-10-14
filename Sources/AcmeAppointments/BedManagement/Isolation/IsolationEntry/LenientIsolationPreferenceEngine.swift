import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient isolation preference calculation.
    protocol LenientIsolationPreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double
    }

    final class LenientIsolationPreferenceRefillsOffsetAdjuster: LenientIsolationPreferenceAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class FlaggedLenientIsolationPreferenceAdjuster: LenientIsolationPreferenceAdjuster {
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

        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentLenientIsolationPreferenceAdjuster: LenientIsolationPreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumLenientIsolationPreferenceAdjuster: LenientIsolationPreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientIsolationPreferenceAdjuster: LenientIsolationPreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingLenientIsolationPreferenceAdjuster: LenientIsolationPreferenceAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientIsolationPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the lenient isolation preference steps in order and keeps a trace of each.
    final class LenientIsolationPreferenceEngine {
        var steps: [any LenientIsolationPreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientIsolationPreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientIsolationPreference) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [LenientIsolationPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientIsolationPreferenceEngine(_ flags: Kit.Flags.Registry) -> LenientIsolationPreferenceEngine {
        return LenientIsolationPreferenceEngine(
            steps: [
                LenientIsolationPreferenceRefillsOffsetAdjuster(weight: 0.56),
                FlaggedLenientIsolationPreferenceAdjuster(
                    flags: flags,
                    flag: "lenient-isolation-preference-regional",
                    percent: 0.3
                ),
                PercentLenientIsolationPreferenceAdjuster(percent: -20.9),
                MinimumLenientIsolationPreferenceAdjuster(minimum: 9.9),
                CapLenientIsolationPreferenceAdjuster(cap: 37619.0),
                RoundingLenientIsolationPreferenceAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 49022.9
        )
    }
}
