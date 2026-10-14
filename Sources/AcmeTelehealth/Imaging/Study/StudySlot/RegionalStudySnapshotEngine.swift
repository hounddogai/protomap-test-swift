import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the regional study snapshot calculation.
    protocol RegionalStudySnapshotStep {
        func describe() -> String
        func adjust(_ item: RegionalStudySnapshot, value: Double) -> Double
    }

    final class RoundingRegionalStudySnapshotAdjuster: RegionalStudySnapshotStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalStudySnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalStudySnapshotAdjuster: RegionalStudySnapshotStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalStudySnapshot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapRegionalStudySnapshotAdjuster: RegionalStudySnapshotStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalStudySnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameRegionalStudySnapshotAdjuster: RegionalStudySnapshotStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalStudySnapshot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional study snapshot steps in order and keeps a trace of each.
    final class RegionalStudySnapshotEngine {
        var steps: [any RegionalStudySnapshotStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalStudySnapshotStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalStudySnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RegionalStudySnapshotStep = steps[index]
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

        func evaluateAll(_ items: [RegionalStudySnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalStudySnapshotEngine() -> RegionalStudySnapshotEngine {
        return RegionalStudySnapshotEngine(
            steps: [
                RoundingRegionalStudySnapshotAdjuster(step: 5.0),
                MinimumRegionalStudySnapshotAdjuster(minimum: 13.2),
                CapRegionalStudySnapshotAdjuster(cap: 42670.0),
                NameRegionalStudySnapshotAdjuster(factors: ["west": 0.8]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 74856.5
        )
    }
}
