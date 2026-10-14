import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert snapshot calculation.
    protocol AlertSnapshotModifier {
        func describe() -> String
        func adjust(_ item: AlertSnapshot, value: Double) -> Double
    }

    final class PercentAlertSnapshotAdjuster: AlertSnapshotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AlertSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitAlertSnapshotAdjuster: AlertSnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: AlertSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAlertSnapshotAdjuster: AlertSnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAlertSnapshotAdjuster: AlertSnapshotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAlertSnapshotAdjuster: AlertSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedAlertSnapshotAdjuster: AlertSnapshotModifier {
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

        func adjust(_ item: AlertSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the alert snapshot steps in order and keeps a trace of each.
    final class AlertSnapshotEngine {
        var steps: [any AlertSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AlertSnapshot) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [AlertSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAlertSnapshotEngine(_ flags: Kit.Flags.Registry) -> AlertSnapshotEngine {
        return AlertSnapshotEngine(
            steps: [
                PercentAlertSnapshotAdjuster(percent: 12.4),
                UnitAlertSnapshotAdjuster(factors: ["retail": 0.89]),
                MinimumAlertSnapshotAdjuster(minimum: 9.4),
                CapAlertSnapshotAdjuster(cap: 4536.0),
                RoundingAlertSnapshotAdjuster(step: 5.0),
                FlaggedAlertSnapshotAdjuster(flags: flags, flag: "alert-snapshot-weighted", percent: -3.1),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 80332.6
        )
    }
}
