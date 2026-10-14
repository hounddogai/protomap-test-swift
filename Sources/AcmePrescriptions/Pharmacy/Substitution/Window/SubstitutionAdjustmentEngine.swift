import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution adjustment calculation.
    protocol SubstitutionAdjustmentModifier {
        func describe() -> String
        func adjust(_ item: SubstitutionAdjustment, value: Double) -> Double
    }

    final class PercentSubstitutionAdjustmentAdjuster: SubstitutionAdjustmentModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionAdjustment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SubstitutionAdjustmentScoreOffsetAdjuster: SubstitutionAdjustmentModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: SubstitutionAdjustment, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapSubstitutionAdjustmentAdjuster: SubstitutionAdjustmentModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SubstitutionAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingSubstitutionAdjustmentAdjuster: SubstitutionAdjustmentModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionAdjustment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedSubstitutionAdjustmentAdjuster: SubstitutionAdjustmentModifier {
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

        func adjust(_ item: SubstitutionAdjustment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution adjustment steps in order and keeps a trace of each.
    final class SubstitutionAdjustmentEngine {
        var steps: [any SubstitutionAdjustmentModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionAdjustmentModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SubstitutionAdjustment) -> Double {
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

        func evaluateAll(_ items: [SubstitutionAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSubstitutionAdjustmentEngine(_ flags: Kit.Flags.Registry) -> SubstitutionAdjustmentEngine {
        return SubstitutionAdjustmentEngine(
            steps: [
                PercentSubstitutionAdjustmentAdjuster(percent: -21.3),
                SubstitutionAdjustmentScoreOffsetAdjuster(weight: 0.05),
                CapSubstitutionAdjustmentAdjuster(cap: 24232.0),
                RoundingSubstitutionAdjustmentAdjuster(step: 0.5),
                FlaggedSubstitutionAdjustmentAdjuster(
                    flags: flags,
                    flag: "substitution-adjustment-global",
                    percent: 9.9
                ),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 74444.1
        )
    }
}
