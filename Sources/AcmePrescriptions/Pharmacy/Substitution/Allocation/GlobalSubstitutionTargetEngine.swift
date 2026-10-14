import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the global substitution target calculation.
    protocol GlobalSubstitutionTargetModifier {
        func describe() -> String
        func adjust(_ item: GlobalSubstitutionTarget, value: Double) -> Double
    }

    final class PercentGlobalSubstitutionTargetAdjuster: GlobalSubstitutionTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalSubstitutionTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedGlobalSubstitutionTargetAdjuster: GlobalSubstitutionTargetModifier {
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

        func adjust(_ item: GlobalSubstitutionTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalSubstitutionTargetAdjuster: GlobalSubstitutionTargetModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSubstitutionTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global substitution target steps in order and keeps a trace of each.
    final class GlobalSubstitutionTargetEngine {
        var steps: [any GlobalSubstitutionTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSubstitutionTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalSubstitutionTarget) -> Double {
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

        func evaluateAll(_ items: [GlobalSubstitutionTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalSubstitutionTargetEngine(_ flags: Kit.Flags.Registry) -> GlobalSubstitutionTargetEngine {
        return GlobalSubstitutionTargetEngine(
            steps: [
                PercentGlobalSubstitutionTargetAdjuster(percent: -0.4),
                FlaggedGlobalSubstitutionTargetAdjuster(
                    flags: flags,
                    flag: "global-substitution-target-capped",
                    percent: -8.3
                ),
                MinimumGlobalSubstitutionTargetAdjuster(minimum: 7.7),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 66547.7
        )
    }
}
