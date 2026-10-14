import AcmePlatform
import Foundation

extension Consent {
    /// One step of the manual witness rollup calculation.
    protocol ManualWitnessRollupModifier {
        func describe() -> String
        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double
    }

    final class CountryManualWitnessRollupAdjuster: ManualWitnessRollupModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualWitnessRollupWindowDaysOffsetAdjuster: ManualWitnessRollupModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class CapManualWitnessRollupAdjuster: ManualWitnessRollupModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedManualWitnessRollupAdjuster: ManualWitnessRollupModifier {
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

        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentManualWitnessRollupAdjuster: ManualWitnessRollupModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualWitnessRollupAdjuster: ManualWitnessRollupModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualWitnessRollup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the manual witness rollup steps in order and keeps a trace of each.
    final class ManualWitnessRollupEngine {
        var steps: [any ManualWitnessRollupModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualWitnessRollupModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualWitnessRollup) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualWitnessRollupModifier = steps[index]
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

        func evaluateAll(_ items: [ManualWitnessRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualWitnessRollupEngine(_ flags: Kit.Flags.Registry) -> ManualWitnessRollupEngine {
        return ManualWitnessRollupEngine(
            steps: [
                CountryManualWitnessRollupAdjuster(factors: ["retail": 0.91, "online": 1.37, "north": 1.23]),
                ManualWitnessRollupWindowDaysOffsetAdjuster(weight: 1.29),
                CapManualWitnessRollupAdjuster(cap: 33959.0),
                FlaggedManualWitnessRollupAdjuster(flags: flags, flag: "manual-witness-rollup-adaptive", percent: 7.0),
                PercentManualWitnessRollupAdjuster(percent: 20.3),
                RoundingManualWitnessRollupAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 33873.6
        )
    }
}
