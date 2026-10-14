import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending risk score checkpoint calculation.
    protocol PendingRiskScoreCheckpointFactor {
        func describe() -> String
        func adjust(_ item: PendingRiskScoreCheckpoint, value: Double) -> Double
    }

    final class RoundingPendingRiskScoreCheckpointAdjuster: PendingRiskScoreCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingRiskScoreCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumPendingRiskScoreCheckpointAdjuster: PendingRiskScoreCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: PendingRiskScoreCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PendingRiskScoreCheckpointBudgetOffsetAdjuster: PendingRiskScoreCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: PendingRiskScoreCheckpoint, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class CapPendingRiskScoreCheckpointAdjuster: PendingRiskScoreCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingRiskScoreCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the pending risk score checkpoint steps in order and keeps a trace of each.
    final class PendingRiskScoreCheckpointEngine {
        var steps: [any PendingRiskScoreCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingRiskScoreCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PendingRiskScoreCheckpoint) -> Double {
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

        func evaluateAll(_ items: [PendingRiskScoreCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPendingRiskScoreCheckpointEngine() -> PendingRiskScoreCheckpointEngine {
        return PendingRiskScoreCheckpointEngine(
            steps: [
                RoundingPendingRiskScoreCheckpointAdjuster(step: 0.5),
                MinimumPendingRiskScoreCheckpointAdjuster(minimum: 3.5),
                PendingRiskScoreCheckpointBudgetOffsetAdjuster(weight: 0.36),
                CapPendingRiskScoreCheckpointAdjuster(cap: 13224.0),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 86512.2
        )
    }
}
