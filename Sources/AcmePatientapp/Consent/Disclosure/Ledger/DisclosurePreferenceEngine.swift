import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure preference calculation.
    protocol DisclosurePreferenceAdjuster {
        func describe() -> String
        func adjust(_ item: DisclosurePreference, value: Double) -> Double
    }

    final class WardDisclosurePreferenceAdjuster: DisclosurePreferenceAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: DisclosurePreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedDisclosurePreferenceAdjuster: DisclosurePreferenceAdjuster {
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

        func adjust(_ item: DisclosurePreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredDisclosurePreferenceAdjuster: DisclosurePreferenceAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosurePreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapDisclosurePreferenceAdjuster: DisclosurePreferenceAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DisclosurePreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentDisclosurePreferenceAdjuster: DisclosurePreferenceAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosurePreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDisclosurePreferenceAdjuster: DisclosurePreferenceAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosurePreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the disclosure preference steps in order and keeps a trace of each.
    final class DisclosurePreferenceEngine {
        var steps: [any DisclosurePreferenceAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosurePreferenceAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DisclosurePreference) -> Double {
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

        func evaluateAll(_ items: [DisclosurePreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDisclosurePreferenceEngine(_ flags: Kit.Flags.Registry) -> DisclosurePreferenceEngine {
        return DisclosurePreferenceEngine(
            steps: [
                WardDisclosurePreferenceAdjuster(factors: ["central": 1.34, "east": 1.24, "north": 1.16]),
                FlaggedDisclosurePreferenceAdjuster(
                    flags: flags,
                    flag: "disclosure-preference-adaptive",
                    percent: 8.2
                ),
                TieredDisclosurePreferenceAdjuster(bounds: [548.0, 1933.0], rates: [0.88, 1.15]),
                CapDisclosurePreferenceAdjuster(cap: 30776.0),
                PercentDisclosurePreferenceAdjuster(percent: -17.9),
                MinimumDisclosurePreferenceAdjuster(minimum: 8.2),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 13048.9
        )
    }
}
