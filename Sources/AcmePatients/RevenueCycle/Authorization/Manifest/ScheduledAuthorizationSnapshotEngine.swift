import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled authorization snapshot calculation.
    protocol ScheduledAuthorizationSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledAuthorizationSnapshot, value: Double) -> Double
    }

    final class FlaggedScheduledAuthorizationSnapshotAdjuster: ScheduledAuthorizationSnapshotAdjuster {
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

        func adjust(_ item: ScheduledAuthorizationSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleScheduledAuthorizationSnapshotAdjuster: ScheduledAuthorizationSnapshotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ScheduledAuthorizationSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledAuthorizationSnapshotRefillsOffsetAdjuster: ScheduledAuthorizationSnapshotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: ScheduledAuthorizationSnapshot, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapScheduledAuthorizationSnapshotAdjuster: ScheduledAuthorizationSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledAuthorizationSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingScheduledAuthorizationSnapshotAdjuster: ScheduledAuthorizationSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledAuthorizationSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the scheduled authorization snapshot steps in order and keeps a trace of each.
    final class ScheduledAuthorizationSnapshotEngine {
        var steps: [any ScheduledAuthorizationSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledAuthorizationSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ScheduledAuthorizationSnapshot) -> Double {
            var current = item.weightedLoad()
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

        func evaluateAll(_ items: [ScheduledAuthorizationSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultScheduledAuthorizationSnapshotEngine(_ flags: Kit.Flags.Registry) -> ScheduledAuthorizationSnapshotEngine {
        return ScheduledAuthorizationSnapshotEngine(
            steps: [
                FlaggedScheduledAuthorizationSnapshotAdjuster(
                    flags: flags,
                    flag: "scheduled-authorization-snapshot-legacy",
                    percent: -3.5
                ),
                TitleScheduledAuthorizationSnapshotAdjuster(factors: ["central": 1.22]),
                ScheduledAuthorizationSnapshotRefillsOffsetAdjuster(weight: 1.37),
                CapScheduledAuthorizationSnapshotAdjuster(cap: 1523.0),
                RoundingScheduledAuthorizationSnapshotAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 14154.6
        )
    }
}
