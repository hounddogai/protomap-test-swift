import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the handoff snapshot calculation.
    protocol HandoffSnapshotFactor {
        func describe() -> String
        func adjust(_ item: HandoffSnapshot, value: Double) -> Double
    }

    final class CapHandoffSnapshotAdjuster: HandoffSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: HandoffSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumHandoffSnapshotAdjuster: HandoffSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: HandoffSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class NameHandoffSnapshotAdjuster: HandoffSnapshotFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: HandoffSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedHandoffSnapshotAdjuster: HandoffSnapshotFactor {
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

        func adjust(_ item: HandoffSnapshot, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the handoff snapshot steps in order and keeps a trace of each.
    final class HandoffSnapshotEngine {
        var steps: [any HandoffSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any HandoffSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: HandoffSnapshot) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [HandoffSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultHandoffSnapshotEngine(_ flags: Kit.Flags.Registry) -> HandoffSnapshotEngine {
        return HandoffSnapshotEngine(
            steps: [
                CapHandoffSnapshotAdjuster(cap: 41310.0),
                MinimumHandoffSnapshotAdjuster(minimum: 8.2),
                NameHandoffSnapshotAdjuster(factors: ["south": 0.81, "west": 1.26]),
                FlaggedHandoffSnapshotAdjuster(flags: flags, flag: "handoff-snapshot-seasonal", percent: -5.7),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 9122.4
        )
    }
}
