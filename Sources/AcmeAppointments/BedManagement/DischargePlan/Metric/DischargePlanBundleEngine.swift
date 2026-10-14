import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan bundle calculation.
    protocol DischargePlanBundleStep {
        func describe() -> String
        func adjust(_ item: DischargePlanBundle, value: Double) -> Double
    }

    final class MinimumDischargePlanBundleAdjuster: DischargePlanBundleStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanBundle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDischargePlanBundleAdjuster: DischargePlanBundleStep {
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

        func adjust(_ item: DischargePlanBundle, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingDischargePlanBundleAdjuster: DischargePlanBundleStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DischargePlanBundle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the discharge plan bundle steps in order and keeps a trace of each.
    final class DischargePlanBundleEngine {
        var steps: [any DischargePlanBundleStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanBundleStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: DischargePlanBundle) -> Double {
            var current = item.effectiveValue()
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

        func evaluateAll(_ items: [DischargePlanBundle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultDischargePlanBundleEngine(_ flags: Kit.Flags.Registry) -> DischargePlanBundleEngine {
        return DischargePlanBundleEngine(
            steps: [
                MinimumDischargePlanBundleAdjuster(minimum: 19.2),
                FlaggedDischargePlanBundleAdjuster(
                    flags: flags,
                    flag: "discharge-plan-bundle-regional",
                    percent: -6.6
                ),
                RoundingDischargePlanBundleAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 47907.5
        )
    }
}
