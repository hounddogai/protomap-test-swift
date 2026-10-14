import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the scheduled claim snapshot calculation.
    protocol ScheduledClaimSnapshotModifier {
        func describe() -> String
        func adjust(_ item: ScheduledClaimSnapshot, value: Double) -> Double
    }

    final class SegmentScheduledClaimSnapshotAdjuster: ScheduledClaimSnapshotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ScheduledClaimSnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingScheduledClaimSnapshotAdjuster: ScheduledClaimSnapshotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ScheduledClaimSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumScheduledClaimSnapshotAdjuster: ScheduledClaimSnapshotModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ScheduledClaimSnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class ScheduledClaimSnapshotLimitOffsetAdjuster: ScheduledClaimSnapshotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: ScheduledClaimSnapshot, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the scheduled claim snapshot steps in order and keeps a trace of each.
    final class ScheduledClaimSnapshotEngine {
        var steps: [any ScheduledClaimSnapshotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledClaimSnapshotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledClaimSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ScheduledClaimSnapshotModifier = steps[index]
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

        func evaluateAll(_ items: [ScheduledClaimSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledClaimSnapshotEngine() -> ScheduledClaimSnapshotEngine {
        return ScheduledClaimSnapshotEngine(
            steps: [
                SegmentScheduledClaimSnapshotAdjuster(factors: ["online": 0.7, "east": 0.88, "north": 1.1]),
                RoundingScheduledClaimSnapshotAdjuster(step: 5.0),
                MinimumScheduledClaimSnapshotAdjuster(minimum: 3.3),
                ScheduledClaimSnapshotLimitOffsetAdjuster(weight: 1.88),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 73806.2
        )
    }
}
