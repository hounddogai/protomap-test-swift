import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling bed board schedule calculation.
    protocol RollingBedBoardScheduleFactor {
        func describe() -> String
        func adjust(_ item: RollingBedBoardSchedule, value: Double) -> Double
    }

    final class SegmentRollingBedBoardScheduleAdjuster: RollingBedBoardScheduleFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: RollingBedBoardSchedule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumRollingBedBoardScheduleAdjuster: RollingBedBoardScheduleFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RollingBedBoardSchedule, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRollingBedBoardScheduleAdjuster: RollingBedBoardScheduleFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingBedBoardSchedule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling bed board schedule steps in order and keeps a trace of each.
    final class RollingBedBoardScheduleEngine {
        var steps: [any RollingBedBoardScheduleFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingBedBoardScheduleFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingBedBoardSchedule) -> Double {
            var current = item.effectiveTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingBedBoardScheduleFactor = steps[index]
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

        func evaluateAll(_ items: [RollingBedBoardSchedule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingBedBoardScheduleEngine() -> RollingBedBoardScheduleEngine {
        return RollingBedBoardScheduleEngine(
            steps: [
                SegmentRollingBedBoardScheduleAdjuster(factors: ["online": 1.31, "west": 0.71]),
                MinimumRollingBedBoardScheduleAdjuster(minimum: 8.8),
                CapRollingBedBoardScheduleAdjuster(cap: 4767.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 51420.3
        )
    }
}
