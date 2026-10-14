import AcmePlatform
import Foundation

extension Consent {
    /// One step of the rolling consent form window calculation.
    protocol RollingConsentFormWindowStep {
        func describe() -> String
        func adjust(_ item: RollingConsentFormWindow, value: Double) -> Double
    }

    final class TitleRollingConsentFormWindowAdjuster: RollingConsentFormWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RollingConsentFormWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRollingConsentFormWindowAdjuster: RollingConsentFormWindowStep {
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

        func adjust(_ item: RollingConsentFormWindow, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RollingConsentFormWindowPriorityOffsetAdjuster: RollingConsentFormWindowStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: RollingConsentFormWindow, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class PercentRollingConsentFormWindowAdjuster: RollingConsentFormWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingConsentFormWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the rolling consent form window steps in order and keeps a trace of each.
    final class RollingConsentFormWindowEngine {
        var steps: [any RollingConsentFormWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingConsentFormWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingConsentFormWindow) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingConsentFormWindowStep = steps[index]
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

        func evaluateAll(_ items: [RollingConsentFormWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingConsentFormWindowEngine(_ flags: Kit.Flags.Registry) -> RollingConsentFormWindowEngine {
        return RollingConsentFormWindowEngine(
            steps: [
                TitleRollingConsentFormWindowAdjuster(factors: ["east": 0.86, "central": 1.09]),
                FlaggedRollingConsentFormWindowAdjuster(
                    flags: flags,
                    flag: "rolling-consent-form-window-tiered",
                    percent: 4.9
                ),
                RollingConsentFormWindowPriorityOffsetAdjuster(weight: 1.09),
                PercentRollingConsentFormWindowAdjuster(percent: 20.8),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 17902.6
        )
    }
}
