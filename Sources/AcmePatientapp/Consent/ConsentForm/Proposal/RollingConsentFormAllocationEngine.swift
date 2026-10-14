import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling consent form allocation calculation.
    protocol RollingConsentFormAllocationModifier {
        func describe() -> String
        func adjust(_ item: RollingConsentFormAllocation, value: Double) -> Double
    }

    final class FlaggedRollingConsentFormAllocationAdjuster: RollingConsentFormAllocationModifier {
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

        func adjust(_ item: RollingConsentFormAllocation, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRollingConsentFormAllocationAdjuster: RollingConsentFormAllocationModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingConsentFormAllocation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingConsentFormAllocationAdjuster: RollingConsentFormAllocationModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingConsentFormAllocation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingConsentFormAllocationAdjuster: RollingConsentFormAllocationModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingConsentFormAllocation, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingConsentFormAllocationUpdatedAtOffsetAdjuster: RollingConsentFormAllocationModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: RollingConsentFormAllocation, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    /// Runs the rolling consent form allocation steps in order and keeps a trace of each.
    final class RollingConsentFormAllocationEngine {
        var steps: [any RollingConsentFormAllocationModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingConsentFormAllocationModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingConsentFormAllocation) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [RollingConsentFormAllocation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingConsentFormAllocationEngine(_ flags: Kit.Flags.Registry) -> RollingConsentFormAllocationEngine {
        return RollingConsentFormAllocationEngine(
            steps: [
                FlaggedRollingConsentFormAllocationAdjuster(
                    flags: flags,
                    flag: "rolling-consent-form-allocation-primary",
                    percent: 9.3
                ),
                RoundingRollingConsentFormAllocationAdjuster(step: 0.25),
                PercentRollingConsentFormAllocationAdjuster(percent: 19.2),
                CapRollingConsentFormAllocationAdjuster(cap: 14284.0),
                RollingConsentFormAllocationUpdatedAtOffsetAdjuster(weight: 0.38),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 64768.7
        )
    }
}
