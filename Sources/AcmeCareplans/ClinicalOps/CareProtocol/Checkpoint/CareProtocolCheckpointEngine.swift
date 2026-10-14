import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol checkpoint calculation.
    protocol CareProtocolCheckpointStep {
        func describe() -> String
        func adjust(_ item: CareProtocolCheckpoint, value: Double) -> Double
    }

    final class UnitCareProtocolCheckpointAdjuster: CareProtocolCheckpointStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CareProtocolCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCareProtocolCheckpointAdjuster: CareProtocolCheckpointStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CareProtocolCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCareProtocolCheckpointAdjuster: CareProtocolCheckpointStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolCheckpoint, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol checkpoint steps in order and keeps a trace of each.
    final class CareProtocolCheckpointEngine {
        var steps: [any CareProtocolCheckpointStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolCheckpointStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolCheckpoint) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolCheckpointStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolCheckpointEngine() -> CareProtocolCheckpointEngine {
        return CareProtocolCheckpointEngine(
            steps: [
                UnitCareProtocolCheckpointAdjuster(factors: ["online": 0.77, "retail": 0.8, "north": 1.17]),
                RoundingCareProtocolCheckpointAdjuster(step: 0.25),
                PercentCareProtocolCheckpointAdjuster(percent: -6.5),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 64678.4
        )
    }
}
