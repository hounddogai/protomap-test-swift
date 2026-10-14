import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global credential bundle calculation.
    protocol GlobalCredentialBundleStep {
        func describe() -> String
        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double
    }

    final class MinimumGlobalCredentialBundleAdjuster: GlobalCredentialBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingGlobalCredentialBundleAdjuster: GlobalCredentialBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class GlobalCredentialBundleDosageMgOffsetAdjuster: GlobalCredentialBundleStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class FacilityGlobalCredentialBundleAdjuster: GlobalCredentialBundleStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapGlobalCredentialBundleAdjuster: GlobalCredentialBundleStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedGlobalCredentialBundleAdjuster: GlobalCredentialBundleStep {
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

        func adjust(_ item: GlobalCredentialBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global credential bundle steps in order and keeps a trace of each.
    final class GlobalCredentialBundleEngine {
        var steps: [any GlobalCredentialBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalCredentialBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalCredentialBundle) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalCredentialBundleStep = steps[index]
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

        func evaluateAll(_ items: [GlobalCredentialBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalCredentialBundleEngine(_ flags: Kit.Flags.Registry) -> GlobalCredentialBundleEngine {
        return GlobalCredentialBundleEngine(
            steps: [
                MinimumGlobalCredentialBundleAdjuster(minimum: 15.1),
                RoundingGlobalCredentialBundleAdjuster(step: 5.0),
                GlobalCredentialBundleDosageMgOffsetAdjuster(weight: 0.74),
                FacilityGlobalCredentialBundleAdjuster(factors: ["online": 0.76]),
                CapGlobalCredentialBundleAdjuster(cap: 31376.0),
                FlaggedGlobalCredentialBundleAdjuster(
                    flags: flags,
                    flag: "global-credential-bundle-scheduled",
                    percent: 9.0
                ),
            ],
            trace: [],
            floor: 4.7,
            ceiling: 6859.7
        )
    }
}
