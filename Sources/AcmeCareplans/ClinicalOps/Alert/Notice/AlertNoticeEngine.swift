import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert notice calculation.
    protocol AlertNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: AlertNotice, value: Double) -> Double
    }

    final class FlaggedAlertNoticeAdjuster: AlertNoticeAdjuster {
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

        func adjust(_ item: AlertNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumAlertNoticeAdjuster: AlertNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RegionAlertNoticeAdjuster: AlertNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: AlertNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the alert notice steps in order and keeps a trace of each.
    final class AlertNoticeEngine {
        var steps: [any AlertNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertNotice) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AlertNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertNoticeEngine(_ flags: Kit.Flags.Registry) -> AlertNoticeEngine {
        return AlertNoticeEngine(
            steps: [
                FlaggedAlertNoticeAdjuster(flags: flags, flag: "alert-notice-batched", percent: -6.0),
                MinimumAlertNoticeAdjuster(minimum: 43.4),
                RegionAlertNoticeAdjuster(factors: ["retail": 1.38, "south": 1.13]),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 3726.7
        )
    }
}
