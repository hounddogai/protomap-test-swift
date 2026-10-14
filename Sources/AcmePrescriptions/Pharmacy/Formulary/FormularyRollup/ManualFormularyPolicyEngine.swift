import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the manual formulary policy calculation.
    protocol ManualFormularyPolicyFactor {
        func describe() -> String
        func adjust(_ item: ManualFormularyPolicy, value: Double) -> Double
    }

    final class PercentManualFormularyPolicyAdjuster: ManualFormularyPolicyFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualFormularyPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedManualFormularyPolicyAdjuster: ManualFormularyPolicyFactor {
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

        func adjust(_ item: ManualFormularyPolicy, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapManualFormularyPolicyAdjuster: ManualFormularyPolicyFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualFormularyPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ManualFormularyPolicyRetriesOffsetAdjuster: ManualFormularyPolicyFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: ManualFormularyPolicy, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the manual formulary policy steps in order and keeps a trace of each.
    final class ManualFormularyPolicyEngine {
        var steps: [any ManualFormularyPolicyFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualFormularyPolicyFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualFormularyPolicy) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [ManualFormularyPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualFormularyPolicyEngine(_ flags: Kit.Flags.Registry) -> ManualFormularyPolicyEngine {
        return ManualFormularyPolicyEngine(
            steps: [
                PercentManualFormularyPolicyAdjuster(percent: 2.4),
                FlaggedManualFormularyPolicyAdjuster(
                    flags: flags,
                    flag: "manual-formulary-policy-batched",
                    percent: 1.9
                ),
                CapManualFormularyPolicyAdjuster(cap: 21516.0),
                ManualFormularyPolicyRetriesOffsetAdjuster(weight: 0.72),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 35165.3
        )
    }
}
