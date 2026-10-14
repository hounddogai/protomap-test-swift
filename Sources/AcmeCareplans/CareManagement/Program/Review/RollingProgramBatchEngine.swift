import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the rolling program batch calculation.
    protocol RollingProgramBatchModifier {
        func describe() -> String
        func adjust(_ item: RollingProgramBatch, value: Double) -> Double
    }

    final class NameRollingProgramBatchAdjuster: RollingProgramBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingProgramBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RollingProgramBatchRateOffsetAdjuster: RollingProgramBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: RollingProgramBatch, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class CapRollingProgramBatchAdjuster: RollingProgramBatchModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingProgramBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the rolling program batch steps in order and keeps a trace of each.
    final class RollingProgramBatchEngine {
        var steps: [any RollingProgramBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingProgramBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingProgramBatch) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RollingProgramBatchModifier = steps[index]
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

        func evaluateAll(_ items: [RollingProgramBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingProgramBatchEngine() -> RollingProgramBatchEngine {
        return RollingProgramBatchEngine(
            steps: [
                NameRollingProgramBatchAdjuster(factors: ["south": 1.35]),
                RollingProgramBatchRateOffsetAdjuster(weight: 0.04),
                CapRollingProgramBatchAdjuster(cap: 44842.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 8821.6
        )
    }
}
