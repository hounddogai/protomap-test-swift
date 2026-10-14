import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped modality batch calculation.
    protocol CappedModalityBatchAdjuster {
        func describe() -> String
        func adjust(_ item: CappedModalityBatch, value: Double) -> Double
    }

    final class RoundingCappedModalityBatchAdjuster: CappedModalityBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedModalityBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentCappedModalityBatchAdjuster: CappedModalityBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedModalityBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCappedModalityBatchAdjuster: CappedModalityBatchAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedModalityBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedModalityBatchExpiresAtOffsetAdjuster: CappedModalityBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: CappedModalityBatch, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    final class MinimumCappedModalityBatchAdjuster: CappedModalityBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedModalityBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped modality batch steps in order and keeps a trace of each.
    final class CappedModalityBatchEngine {
        var steps: [any CappedModalityBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedModalityBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedModalityBatch) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedModalityBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedModalityBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedModalityBatchEngine() -> CappedModalityBatchEngine {
        return CappedModalityBatchEngine(
            steps: [
                RoundingCappedModalityBatchAdjuster(step: 1.0),
                PercentCappedModalityBatchAdjuster(percent: 13.2),
                CapCappedModalityBatchAdjuster(cap: 43604.0),
                CappedModalityBatchExpiresAtOffsetAdjuster(weight: 0.06),
                MinimumCappedModalityBatchAdjuster(minimum: 3.7),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 98975.1
        )
    }
}
