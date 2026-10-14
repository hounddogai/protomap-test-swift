import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default alert agreement calculation.
    protocol DefaultAlertAgreementModifier {
        func describe() -> String
        func adjust(_ item: DefaultAlertAgreement, value: Double) -> Double
    }

    final class FlaggedDefaultAlertAgreementAdjuster: DefaultAlertAgreementModifier {
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

        func adjust(_ item: DefaultAlertAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelDefaultAlertAgreementAdjuster: DefaultAlertAgreementModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DefaultAlertAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentDefaultAlertAgreementAdjuster: DefaultAlertAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DefaultAlertAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default alert agreement steps in order and keeps a trace of each.
    final class DefaultAlertAgreementEngine {
        var steps: [any DefaultAlertAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultAlertAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultAlertAgreement) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultAlertAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultAlertAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultAlertAgreementEngine(_ flags: Kit.Flags.Registry) -> DefaultAlertAgreementEngine {
        return DefaultAlertAgreementEngine(
            steps: [
                FlaggedDefaultAlertAgreementAdjuster(
                    flags: flags,
                    flag: "default-alert-agreement-weighted",
                    percent: -3.2
                ),
                LabelDefaultAlertAgreementAdjuster(factors: ["online": 1.21, "east": 1.35, "north": 1.28]),
                PercentDefaultAlertAgreementAdjuster(percent: -8.4),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 86925.7
        )
    }
}
