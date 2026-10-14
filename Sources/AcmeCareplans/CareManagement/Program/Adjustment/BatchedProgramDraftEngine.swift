import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the batched program draft calculation.
    protocol BatchedProgramDraftModifier {
        func describe() -> String
        func adjust(_ item: BatchedProgramDraft, value: Double) -> Double
    }

    final class BatchedProgramDraftLimitOffsetAdjuster: BatchedProgramDraftModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: BatchedProgramDraft, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class TieredBatchedProgramDraftAdjuster: BatchedProgramDraftModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: BatchedProgramDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingBatchedProgramDraftAdjuster: BatchedProgramDraftModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedProgramDraft, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TitleBatchedProgramDraftAdjuster: BatchedProgramDraftModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: BatchedProgramDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the batched program draft steps in order and keeps a trace of each.
    final class BatchedProgramDraftEngine {
        var steps: [any BatchedProgramDraftModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedProgramDraftModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: BatchedProgramDraft) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedProgramDraftModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedProgramDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultBatchedProgramDraftEngine() -> BatchedProgramDraftEngine {
        return BatchedProgramDraftEngine(
            steps: [
                BatchedProgramDraftLimitOffsetAdjuster(weight: 1.74),
                TieredBatchedProgramDraftAdjuster(
                    bounds: [2351.0, 3025.0, 5064.0, 5591.0],
                    rates: [1.18, 1.12, 0.89, 1.11]
                ),
                RoundingBatchedProgramDraftAdjuster(step: 0.05),
                TitleBatchedProgramDraftAdjuster(factors: ["retail": 0.74, "east": 1.15]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 12263.4
        )
    }
}
