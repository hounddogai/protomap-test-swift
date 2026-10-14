import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert claim calculation.
    protocol AlertClaimModifier {
        func describe() -> String
        func adjust(_ item: AlertClaim, value: Double) -> Double
    }

    final class FlaggedAlertClaimAdjuster: AlertClaimModifier {
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

        func adjust(_ item: AlertClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAlertClaimAdjuster: AlertClaimModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAlertClaimAdjuster: AlertClaimModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AlertClaimMaximumOffsetAdjuster: AlertClaimModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: AlertClaim, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the alert claim steps in order and keeps a trace of each.
    final class AlertClaimEngine {
        var steps: [any AlertClaimModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertClaimModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertClaim) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertClaimModifier = steps[index]
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

        func evaluateAll(_ items: [AlertClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertClaimEngine(_ flags: Kit.Flags.Registry) -> AlertClaimEngine {
        return AlertClaimEngine(
            steps: [
                FlaggedAlertClaimAdjuster(flags: flags, flag: "alert-claim-fallback", percent: 8.0),
                CapAlertClaimAdjuster(cap: 17329.0),
                RoundingAlertClaimAdjuster(step: 1.0),
                AlertClaimMaximumOffsetAdjuster(weight: 1.79),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 87455.4
        )
    }
}
