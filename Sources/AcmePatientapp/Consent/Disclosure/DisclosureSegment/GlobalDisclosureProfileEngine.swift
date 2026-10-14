import AcmePlatform
import Foundation

extension Consent {
    /// One step of the global disclosure profile calculation.
    protocol GlobalDisclosureProfileFactor {
        func describe() -> String
        func adjust(_ item: GlobalDisclosureProfile, value: Double) -> Double
    }

    final class RoundingGlobalDisclosureProfileAdjuster: GlobalDisclosureProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalDisclosureProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedGlobalDisclosureProfileAdjuster: GlobalDisclosureProfileFactor {
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

        func adjust(_ item: GlobalDisclosureProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredGlobalDisclosureProfileAdjuster: GlobalDisclosureProfileFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalDisclosureProfile, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalDisclosureProfileAdjuster: GlobalDisclosureProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalDisclosureProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentGlobalDisclosureProfileAdjuster: GlobalDisclosureProfileFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalDisclosureProfile, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global disclosure profile steps in order and keeps a trace of each.
    final class GlobalDisclosureProfileEngine {
        var steps: [any GlobalDisclosureProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalDisclosureProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalDisclosureProfile) -> Double {
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

        func evaluateAll(_ items: [GlobalDisclosureProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalDisclosureProfileEngine(_ flags: Kit.Flags.Registry) -> GlobalDisclosureProfileEngine {
        return GlobalDisclosureProfileEngine(
            steps: [
                RoundingGlobalDisclosureProfileAdjuster(step: 0.25),
                FlaggedGlobalDisclosureProfileAdjuster(
                    flags: flags,
                    flag: "global-disclosure-profile-pending",
                    percent: 8.2
                ),
                TieredGlobalDisclosureProfileAdjuster(bounds: [3378.0, 9643.0], rates: [1.07, 1.09]),
                CapGlobalDisclosureProfileAdjuster(cap: 11280.0),
                PercentGlobalDisclosureProfileAdjuster(percent: 21.1),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 91734.8
        )
    }
}
