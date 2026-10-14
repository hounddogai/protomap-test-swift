import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the priority preference calculation.
    protocol PriorityPreferenceStep {
        func describe() -> String
        func adjust(_ item: PriorityPreference, value: Double) -> Double
    }

    final class TieredPriorityPreferenceAdjuster: PriorityPreferenceStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PriorityPreference, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumPriorityPreferenceAdjuster: PriorityPreferenceStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PriorityPreference, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedPriorityPreferenceAdjuster: PriorityPreferenceStep {
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

        func adjust(_ item: PriorityPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPriorityPreferenceAdjuster: PriorityPreferenceStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PriorityPreference, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentPriorityPreferenceAdjuster: PriorityPreferenceStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PriorityPreference, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the priority preference steps in order and keeps a trace of each.
    final class PriorityPreferenceEngine {
        var steps: [any PriorityPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PriorityPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PriorityPreference) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [PriorityPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPriorityPreferenceEngine(_ flags: Kit.Flags.Registry) -> PriorityPreferenceEngine {
        return PriorityPreferenceEngine(
            steps: [
                TieredPriorityPreferenceAdjuster(bounds: [1167.0, 3889.0], rates: [0.91, 1.18]),
                MinimumPriorityPreferenceAdjuster(minimum: 38.1),
                FlaggedPriorityPreferenceAdjuster(flags: flags, flag: "priority-preference-capped", percent: -8.3),
                CapPriorityPreferenceAdjuster(cap: 8258.0),
                PercentPriorityPreferenceAdjuster(percent: -15.1),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 92881.4
        )
    }
}
