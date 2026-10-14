import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled care gap snapshot calculation.
    protocol ScheduledCareGapSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledCareGapSnapshot, value: Double) -> Double
    }

    final class FlaggedScheduledCareGapSnapshotAdjuster: ScheduledCareGapSnapshotAdjuster {
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

        func adjust(_ item: ScheduledCareGapSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledCareGapSnapshotAdjuster: ScheduledCareGapSnapshotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledCareGapSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledCareGapSnapshotAdjuster: ScheduledCareGapSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledCareGapSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapScheduledCareGapSnapshotAdjuster: ScheduledCareGapSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledCareGapSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled care gap snapshot steps in order and keeps a trace of each.
    final class ScheduledCareGapSnapshotEngine {
        var steps: [any ScheduledCareGapSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledCareGapSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledCareGapSnapshot) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledCareGapSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledCareGapSnapshotEngine(_ flags: Kit.Flags.Registry) -> ScheduledCareGapSnapshotEngine {
        return ScheduledCareGapSnapshotEngine(
            steps: [
                FlaggedScheduledCareGapSnapshotAdjuster(
                    flags: flags,
                    flag: "scheduled-care-gap-snapshot-tiered",
                    percent: -4.2
                ),
                PercentScheduledCareGapSnapshotAdjuster(percent: 15.9),
                TieredScheduledCareGapSnapshotAdjuster(bounds: [667.0, 9984.0], rates: [0.82, 1.1]),
                CapScheduledCareGapSnapshotAdjuster(cap: 23423.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 51403.5
        )
    }
}
