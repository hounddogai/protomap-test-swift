import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the float pool checkpoint calculation.
    protocol FloatPoolCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: FloatPoolCheckpoint, value: Double) -> Double
    }

    final class RoundingFloatPoolCheckpointAdjuster: FloatPoolCheckpointAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FloatPoolCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FloatPoolCheckpointWeightOffsetAdjuster: FloatPoolCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: FloatPoolCheckpoint, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class WardFloatPoolCheckpointAdjuster: FloatPoolCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: FloatPoolCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapFloatPoolCheckpointAdjuster: FloatPoolCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FloatPoolCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the float pool checkpoint steps in order and keeps a trace of each.
    final class FloatPoolCheckpointEngine {
        var steps: [any FloatPoolCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FloatPoolCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: FloatPoolCheckpoint) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any FloatPoolCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [FloatPoolCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultFloatPoolCheckpointEngine() -> FloatPoolCheckpointEngine {
        return FloatPoolCheckpointEngine(
            steps: [
                RoundingFloatPoolCheckpointAdjuster(step: 0.5),
                FloatPoolCheckpointWeightOffsetAdjuster(weight: 1.09),
                WardFloatPoolCheckpointAdjuster(factors: ["north": 0.82, "south": 1.26, "central": 0.76]),
                CapFloatPoolCheckpointAdjuster(cap: 12432.0),
            ],
            trace: [],
            floor: 3.9,
            ceiling: 6590.2
        )
    }
}
