import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the transfer checkpoint calculation.
    protocol TransferCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: TransferCheckpoint, value: Double) -> Double
    }

    final class RoundingTransferCheckpointAdjuster: TransferCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TransferCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumTransferCheckpointAdjuster: TransferCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TransferCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class SegmentTransferCheckpointAdjuster: TransferCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: TransferCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the transfer checkpoint steps in order and keeps a trace of each.
    final class TransferCheckpointEngine {
        var steps: [any TransferCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TransferCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: TransferCheckpoint) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TransferCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [TransferCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultTransferCheckpointEngine() -> TransferCheckpointEngine {
        return TransferCheckpointEngine(
            steps: [
                RoundingTransferCheckpointAdjuster(step: 5.0),
                MinimumTransferCheckpointAdjuster(minimum: 41.1),
                SegmentTransferCheckpointAdjuster(factors: ["south": 0.88, "central": 0.84, "east": 1.03]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 7220.9
        )
    }
}
