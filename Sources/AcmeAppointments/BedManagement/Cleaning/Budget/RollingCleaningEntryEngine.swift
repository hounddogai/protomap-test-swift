import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the rolling cleaning entry calculation.
    protocol RollingCleaningEntryAdjuster {
        func describe() -> String
        func adjust(_ item: RollingCleaningEntry, value: Double) -> Double
    }

    final class PercentRollingCleaningEntryAdjuster: RollingCleaningEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingCleaningEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingCleaningEntryAdjuster: RollingCleaningEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCleaningEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingCleaningEntryCeilingOffsetAdjuster: RollingCleaningEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: RollingCleaningEntry, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    /// Runs the rolling cleaning entry steps in order and keeps a trace of each.
    final class RollingCleaningEntryEngine {
        var steps: [any RollingCleaningEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCleaningEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RollingCleaningEntry) -> Double {
            var current = item.effectiveLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingCleaningEntryAdjuster = steps[index]
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

        func evaluateAll(_ items: [RollingCleaningEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRollingCleaningEntryEngine() -> RollingCleaningEntryEngine {
        return RollingCleaningEntryEngine(
            steps: [
                PercentRollingCleaningEntryAdjuster(percent: -23.6),
                CapRollingCleaningEntryAdjuster(cap: 43274.0),
                RollingCleaningEntryCeilingOffsetAdjuster(weight: 0.93),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 57895.8
        )
    }
}
