import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert agreement calculation.
    protocol AlertAgreementStep {
        func describe() -> String
        func adjust(_ item: AlertAgreement, value: Double) -> Double
    }

    final class FlaggedAlertAgreementAdjuster: AlertAgreementStep {
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

        func adjust(_ item: AlertAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class AlertAgreementCreatedAtOffsetAdjuster: AlertAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: AlertAgreement, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentAlertAgreementAdjuster: AlertAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the alert agreement steps in order and keeps a trace of each.
    final class AlertAgreementEngine {
        var steps: [any AlertAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AlertAgreement) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [AlertAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAlertAgreementEngine(_ flags: Kit.Flags.Registry) -> AlertAgreementEngine {
        return AlertAgreementEngine(
            steps: [
                FlaggedAlertAgreementAdjuster(flags: flags, flag: "alert-agreement-weighted", percent: 1.0),
                AlertAgreementCreatedAtOffsetAdjuster(weight: 0.66),
                PercentAlertAgreementAdjuster(percent: 23.5),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 65200.3
        )
    }
}
