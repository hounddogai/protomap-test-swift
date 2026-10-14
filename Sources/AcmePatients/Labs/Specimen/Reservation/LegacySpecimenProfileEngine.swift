import AcmePlatform
import Foundation

extension Labs {
    /// One step of the legacy specimen profile calculation.
    protocol LegacySpecimenProfileStep {
        func describe() -> String
        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double
    }

    final class LabelLegacySpecimenProfileAdjuster: LegacySpecimenProfileStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLegacySpecimenProfileAdjuster: LegacySpecimenProfileStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedLegacySpecimenProfileAdjuster: LegacySpecimenProfileStep {
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

        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLegacySpecimenProfileAdjuster: LegacySpecimenProfileStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LegacySpecimenProfileCostOffsetAdjuster: LegacySpecimenProfileStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class RoundingLegacySpecimenProfileAdjuster: LegacySpecimenProfileStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LegacySpecimenProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the legacy specimen profile steps in order and keeps a trace of each.
    final class LegacySpecimenProfileEngine {
        var steps: [any LegacySpecimenProfileStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LegacySpecimenProfileStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LegacySpecimenProfile) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any LegacySpecimenProfileStep = steps[index]
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

        func evaluateAll(_ items: [LegacySpecimenProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLegacySpecimenProfileEngine(_ flags: Kit.Flags.Registry) -> LegacySpecimenProfileEngine {
        return LegacySpecimenProfileEngine(
            steps: [
                LabelLegacySpecimenProfileAdjuster(factors: ["west": 1.16, "south": 0.91, "central": 0.9]),
                MinimumLegacySpecimenProfileAdjuster(minimum: 4.5),
                FlaggedLegacySpecimenProfileAdjuster(
                    flags: flags,
                    flag: "legacy-specimen-profile-seasonal",
                    percent: -9.5
                ),
                CapLegacySpecimenProfileAdjuster(cap: 7223.0),
                LegacySpecimenProfileCostOffsetAdjuster(weight: 1.87),
                RoundingLegacySpecimenProfileAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 47896.7
        )
    }
}
