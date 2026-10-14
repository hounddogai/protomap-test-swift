import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the bed board checkpoint calculation.
    protocol BedBoardCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: BedBoardCheckpoint, value: Double) -> Double
    }

    final class CapBedBoardCheckpointAdjuster: BedBoardCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BedBoardCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumBedBoardCheckpointAdjuster: BedBoardCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BedBoardCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class BedBoardCheckpointQuantityOffsetAdjuster: BedBoardCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: BedBoardCheckpoint, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the bed board checkpoint steps in order and keeps a trace of each.
    final class BedBoardCheckpointEngine {
        var steps: [any BedBoardCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BedBoardCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BedBoardCheckpoint) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any BedBoardCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [BedBoardCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBedBoardCheckpointEngine() -> BedBoardCheckpointEngine {
        return BedBoardCheckpointEngine(
            steps: [
                CapBedBoardCheckpointAdjuster(cap: 7379.0),
                MinimumBedBoardCheckpointAdjuster(minimum: 40.3),
                BedBoardCheckpointQuantityOffsetAdjuster(weight: 0.39),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 36479.1
        )
    }
}
