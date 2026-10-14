import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the regional alert snapshot calculation.
    protocol RegionalAlertSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalAlertSnapshot, value: Double) -> Double
    }

    final class RegionalAlertSnapshotCostOffsetAdjuster: RegionalAlertSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: RegionalAlertSnapshot, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class FlaggedRegionalAlertSnapshotAdjuster: RegionalAlertSnapshotAdjuster {
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

        func adjust(_ item: RegionalAlertSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRegionalAlertSnapshotAdjuster: RegionalAlertSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalAlertSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentRegionalAlertSnapshotAdjuster: RegionalAlertSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAlertSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRegionalAlertSnapshotAdjuster: RegionalAlertSnapshotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAlertSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional alert snapshot steps in order and keeps a trace of each.
    final class RegionalAlertSnapshotEngine {
        var steps: [any RegionalAlertSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAlertSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RegionalAlertSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalAlertSnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [RegionalAlertSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRegionalAlertSnapshotEngine(_ flags: Kit.Flags.Registry) -> RegionalAlertSnapshotEngine {
        return RegionalAlertSnapshotEngine(
            steps: [
                RegionalAlertSnapshotCostOffsetAdjuster(weight: 1.14),
                FlaggedRegionalAlertSnapshotAdjuster(
                    flags: flags,
                    flag: "regional-alert-snapshot-legacy",
                    percent: 6.7
                ),
                CapRegionalAlertSnapshotAdjuster(cap: 677.0),
                PercentRegionalAlertSnapshotAdjuster(percent: 11.7),
                MinimumRegionalAlertSnapshotAdjuster(minimum: 20.8),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 46555.5
        )
    }
}
