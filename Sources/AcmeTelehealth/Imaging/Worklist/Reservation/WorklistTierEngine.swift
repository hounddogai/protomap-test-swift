import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist tier calculation.
    protocol WorklistTierFactor {
        func describe() -> String
        func adjust(_ item: WorklistTier, value: Double) -> Double
    }

    final class CapWorklistTierAdjuster: WorklistTierFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WorklistTierBatchSizeOffsetAdjuster: WorklistTierFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: WorklistTier, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class MinimumWorklistTierAdjuster: WorklistTierFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitWorklistTierAdjuster: WorklistTierFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: WorklistTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingWorklistTierAdjuster: WorklistTierFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WorklistTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the worklist tier steps in order and keeps a trace of each.
    final class WorklistTierEngine {
        var steps: [any WorklistTierFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistTierFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistTier) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any WorklistTierFactor = steps[index]
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

        func evaluateAll(_ items: [WorklistTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistTierEngine() -> WorklistTierEngine {
        return WorklistTierEngine(
            steps: [
                CapWorklistTierAdjuster(cap: 16957.0),
                WorklistTierBatchSizeOffsetAdjuster(weight: 1.43),
                MinimumWorklistTierAdjuster(minimum: 27.9),
                UnitWorklistTierAdjuster(factors: ["online": 1.11, "central": 1.26, "east": 0.78]),
                RoundingWorklistTierAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 15927.5
        )
    }
}
