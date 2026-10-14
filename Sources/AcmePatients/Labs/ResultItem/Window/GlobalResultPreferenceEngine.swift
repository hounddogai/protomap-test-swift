import AcmePlatform
import Foundation

extension Labs {
    /// One step of the global result preference calculation.
    protocol GlobalResultPreferenceStep {
        func describe() -> String
        func adjust(_ item: GlobalResultPreference, value: Double) -> Double
    }

    final class RoundingGlobalResultPreferenceAdjuster: GlobalResultPreferenceStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalResultPreference, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalResultPreferenceCostOffsetAdjuster: GlobalResultPreferenceStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: GlobalResultPreference, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class FlaggedGlobalResultPreferenceAdjuster: GlobalResultPreferenceStep {
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

        func adjust(_ item: GlobalResultPreference, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitGlobalResultPreferenceAdjuster: GlobalResultPreferenceStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: GlobalResultPreference, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global result preference steps in order and keeps a trace of each.
    final class GlobalResultPreferenceEngine {
        var steps: [any GlobalResultPreferenceStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalResultPreferenceStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: GlobalResultPreference) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalResultPreferenceStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [GlobalResultPreference]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultGlobalResultPreferenceEngine(_ flags: Kit.Flags.Registry) -> GlobalResultPreferenceEngine {
        return GlobalResultPreferenceEngine(
            steps: [
                RoundingGlobalResultPreferenceAdjuster(step: 5.0),
                GlobalResultPreferenceCostOffsetAdjuster(weight: 0.65),
                FlaggedGlobalResultPreferenceAdjuster(
                    flags: flags,
                    flag: "global-result-preference-regional",
                    percent: -7.2
                ),
                UnitGlobalResultPreferenceAdjuster(factors: ["north": 1.25, "west": 1.14, "south": 0.82]),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 22997.5
        )
    }
}
