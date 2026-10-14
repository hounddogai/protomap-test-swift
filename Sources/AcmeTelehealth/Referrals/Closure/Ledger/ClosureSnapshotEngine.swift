import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the closure snapshot calculation.
    protocol ClosureSnapshotStep {
        func describe() -> String
        func adjust(_ item: ClosureSnapshot, value: Double) -> Double
    }

    final class FlaggedClosureSnapshotAdjuster: ClosureSnapshotStep {
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

        func adjust(_ item: ClosureSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClosureSnapshotScoreOffsetAdjuster: ClosureSnapshotStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ClosureSnapshot, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumClosureSnapshotAdjuster: ClosureSnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClosureSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitClosureSnapshotAdjuster: ClosureSnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: ClosureSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClosureSnapshotAdjuster: ClosureSnapshotStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClosureSnapshot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the closure snapshot steps in order and keeps a trace of each.
    final class ClosureSnapshotEngine {
        var steps: [any ClosureSnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClosureSnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClosureSnapshot) -> Double {
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

        func evaluateAll(_ items: [ClosureSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClosureSnapshotEngine(_ flags: Kit.Flags.Registry) -> ClosureSnapshotEngine {
        return ClosureSnapshotEngine(
            steps: [
                FlaggedClosureSnapshotAdjuster(flags: flags, flag: "closure-snapshot-rolling", percent: -1.1),
                ClosureSnapshotScoreOffsetAdjuster(weight: 0.72),
                MinimumClosureSnapshotAdjuster(minimum: 42.4),
                UnitClosureSnapshotAdjuster(factors: ["online": 0.78]),
                PercentClosureSnapshotAdjuster(percent: 10.0),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 68925.8
        )
    }
}
