import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the fallback program batch calculation.
    protocol FallbackProgramBatchFactor {
        func describe() -> String
        func adjust(_ item: FallbackProgramBatch, value: Double) -> Double
    }

    final class MinimumFallbackProgramBatchAdjuster: FallbackProgramBatchFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: FallbackProgramBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapFallbackProgramBatchAdjuster: FallbackProgramBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackProgramBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackProgramBatchAdjuster: FallbackProgramBatchFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackProgramBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the fallback program batch steps in order and keeps a trace of each.
    final class FallbackProgramBatchEngine {
        var steps: [any FallbackProgramBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackProgramBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FallbackProgramBatch) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [FallbackProgramBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFallbackProgramBatchEngine() -> FallbackProgramBatchEngine {
        return FallbackProgramBatchEngine(
            steps: [
                MinimumFallbackProgramBatchAdjuster(minimum: 17.0),
                CapFallbackProgramBatchAdjuster(cap: 19912.0),
                RoundingFallbackProgramBatchAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 42721.4
        )
    }
}
