import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict credential checkpoint calculation.
    protocol StrictCredentialCheckpointModifier {
        func describe() -> String
        func adjust(_ item: StrictCredentialCheckpoint, value: Double) -> Double
    }

    final class StrictCredentialCheckpointQuantityOffsetAdjuster: StrictCredentialCheckpointModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: StrictCredentialCheckpoint, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class PercentStrictCredentialCheckpointAdjuster: StrictCredentialCheckpointModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictCredentialCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingStrictCredentialCheckpointAdjuster: StrictCredentialCheckpointModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictCredentialCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumStrictCredentialCheckpointAdjuster: StrictCredentialCheckpointModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictCredentialCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict credential checkpoint steps in order and keeps a trace of each.
    final class StrictCredentialCheckpointEngine {
        var steps: [any StrictCredentialCheckpointModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictCredentialCheckpointModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StrictCredentialCheckpoint) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [StrictCredentialCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStrictCredentialCheckpointEngine() -> StrictCredentialCheckpointEngine {
        return StrictCredentialCheckpointEngine(
            steps: [
                StrictCredentialCheckpointQuantityOffsetAdjuster(weight: 1.18),
                PercentStrictCredentialCheckpointAdjuster(percent: -1.3),
                RoundingStrictCredentialCheckpointAdjuster(step: 5.0),
                MinimumStrictCredentialCheckpointAdjuster(minimum: 39.0),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 2033.1
        )
    }
}
