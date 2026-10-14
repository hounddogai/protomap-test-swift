import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the follow up snapshot calculation.
    protocol FollowUpSnapshotFactor {
        func describe() -> String
        func adjust(_ item: FollowUpSnapshot, value: Double) -> Double
    }

    final class MinimumFollowUpSnapshotAdjuster: FollowUpSnapshotFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FollowUpSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingFollowUpSnapshotAdjuster: FollowUpSnapshotFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FollowUpSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapFollowUpSnapshotAdjuster: FollowUpSnapshotFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FollowUpSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the follow up snapshot steps in order and keeps a trace of each.
    final class FollowUpSnapshotEngine {
        var steps: [any FollowUpSnapshotFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FollowUpSnapshotFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FollowUpSnapshot) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any FollowUpSnapshotFactor = steps[index]
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

        func evaluateAll(_ items: [FollowUpSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFollowUpSnapshotEngine() -> FollowUpSnapshotEngine {
        return FollowUpSnapshotEngine(
            steps: [
                MinimumFollowUpSnapshotAdjuster(minimum: 25.6),
                RoundingFollowUpSnapshotAdjuster(step: 0.25),
                CapFollowUpSnapshotAdjuster(cap: 26002.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 68270.1
        )
    }
}
