import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched witness summary calculation.
    protocol BatchedWitnessSummaryStep {
        func describe() -> String
        func adjust(_ item: BatchedWitnessSummary, value: Double) -> Double
    }

    final class CapBatchedWitnessSummaryAdjuster: BatchedWitnessSummaryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: BatchedWitnessSummary, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentBatchedWitnessSummaryAdjuster: BatchedWitnessSummaryStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedWitnessSummary, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedWitnessSummaryUpdatedAtOffsetAdjuster: BatchedWitnessSummaryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: BatchedWitnessSummary, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class RegionBatchedWitnessSummaryAdjuster: BatchedWitnessSummaryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: BatchedWitnessSummary, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingBatchedWitnessSummaryAdjuster: BatchedWitnessSummaryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedWitnessSummary, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched witness summary steps in order and keeps a trace of each.
    final class BatchedWitnessSummaryEngine {
        var steps: [any BatchedWitnessSummaryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedWitnessSummaryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedWitnessSummary) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedWitnessSummaryStep = steps[index]
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

        func evaluateAll(_ items: [BatchedWitnessSummary]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedWitnessSummaryEngine() -> BatchedWitnessSummaryEngine {
        return BatchedWitnessSummaryEngine(
            steps: [
                CapBatchedWitnessSummaryAdjuster(cap: 27137.0),
                PercentBatchedWitnessSummaryAdjuster(percent: -5.6),
                BatchedWitnessSummaryUpdatedAtOffsetAdjuster(weight: 1.71),
                RegionBatchedWitnessSummaryAdjuster(factors: ["north": 1.4, "central": 1.01, "online": 1.18]),
                RoundingBatchedWitnessSummaryAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 38744.5
        )
    }
}
