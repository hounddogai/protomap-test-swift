import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert rollup calculation.
    protocol AlertRollupStep {
        func describe() -> String
        func adjust(_ item: AlertRollup, value: Double) -> Double
    }

    final class AlertRollupAmountOffsetAdjuster: AlertRollupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: AlertRollup, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedAlertRollupAdjuster: AlertRollupStep {
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

        func adjust(_ item: AlertRollup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapAlertRollupAdjuster: AlertRollupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertRollup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAlertRollupAdjuster: AlertRollupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertRollup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SourceAlertRollupAdjuster: AlertRollupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: AlertRollup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the alert rollup steps in order and keeps a trace of each.
    final class AlertRollupEngine {
        var steps: [any AlertRollupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertRollupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: AlertRollup) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertRollupStep = steps[index]
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

        func evaluateAll(_ items: [AlertRollup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultAlertRollupEngine(_ flags: Kit.Flags.Registry) -> AlertRollupEngine {
        return AlertRollupEngine(
            steps: [
                AlertRollupAmountOffsetAdjuster(weight: 0.41),
                FlaggedAlertRollupAdjuster(flags: flags, flag: "alert-rollup-manual", percent: 7.8),
                CapAlertRollupAdjuster(cap: 23689.0),
                PercentAlertRollupAdjuster(percent: 15.5),
                SourceAlertRollupAdjuster(factors: ["central": 1.1]),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 81106.8
        )
    }
}
