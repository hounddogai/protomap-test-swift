import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the manual rounding checkpoint calculation.
    protocol ManualRoundingCheckpointFactor {
        func describe() -> String
        func adjust(_ item: ManualRoundingCheckpoint, value: Double) -> Double
    }

    final class PercentManualRoundingCheckpointAdjuster: ManualRoundingCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualRoundingCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingManualRoundingCheckpointAdjuster: ManualRoundingCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualRoundingCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumManualRoundingCheckpointAdjuster: ManualRoundingCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualRoundingCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual rounding checkpoint steps in order and keeps a trace of each.
    final class ManualRoundingCheckpointEngine {
        var steps: [any ManualRoundingCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualRoundingCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ManualRoundingCheckpoint) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [ManualRoundingCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultManualRoundingCheckpointEngine() -> ManualRoundingCheckpointEngine {
        return ManualRoundingCheckpointEngine(
            steps: [
                PercentManualRoundingCheckpointAdjuster(percent: 6.1),
                RoundingManualRoundingCheckpointAdjuster(step: 0.25),
                MinimumManualRoundingCheckpointAdjuster(minimum: 16.6),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 49175.7
        )
    }
}
