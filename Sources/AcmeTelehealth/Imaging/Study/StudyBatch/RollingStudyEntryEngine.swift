import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the rolling study entry calculation.
    protocol RollingStudyEntryFactor {
        func describe() -> String
        func adjust(_ item: RollingStudyEntry, value: Double) -> Double
    }

    final class RoundingRollingStudyEntryAdjuster: RollingStudyEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingStudyEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RollingStudyEntryCeilingOffsetAdjuster: RollingStudyEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: RollingStudyEntry, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class CapRollingStudyEntryAdjuster: RollingStudyEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingStudyEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling study entry steps in order and keeps a trace of each.
    final class RollingStudyEntryEngine {
        var steps: [any RollingStudyEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingStudyEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingStudyEntry) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingStudyEntryFactor = steps[index]
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

        func evaluateAll(_ items: [RollingStudyEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingStudyEntryEngine() -> RollingStudyEntryEngine {
        return RollingStudyEntryEngine(
            steps: [
                RoundingRollingStudyEntryAdjuster(step: 5.0),
                RollingStudyEntryCeilingOffsetAdjuster(weight: 0.92),
                CapRollingStudyEntryAdjuster(cap: 19605.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 41695.6
        )
    }
}
