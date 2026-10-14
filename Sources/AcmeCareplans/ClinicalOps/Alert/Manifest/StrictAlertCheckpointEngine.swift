import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict alert checkpoint calculation.
    protocol StrictAlertCheckpointFactor {
        func describe() -> String
        func adjust(_ item: StrictAlertCheckpoint, value: Double) -> Double
    }

    final class RoundingStrictAlertCheckpointAdjuster: StrictAlertCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictAlertCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapStrictAlertCheckpointAdjuster: StrictAlertCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictAlertCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStrictAlertCheckpointAdjuster: StrictAlertCheckpointFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictAlertCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict alert checkpoint steps in order and keeps a trace of each.
    final class StrictAlertCheckpointEngine {
        var steps: [any StrictAlertCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAlertCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StrictAlertCheckpoint) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [StrictAlertCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStrictAlertCheckpointEngine() -> StrictAlertCheckpointEngine {
        return StrictAlertCheckpointEngine(
            steps: [
                RoundingStrictAlertCheckpointAdjuster(step: 0.25),
                CapStrictAlertCheckpointAdjuster(cap: 7908.0),
                PercentStrictAlertCheckpointAdjuster(percent: -19.4),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 41025.9
        )
    }
}
