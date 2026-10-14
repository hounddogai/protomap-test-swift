import AcmePlatform
import Foundation

extension Consent {
    /// One step of the batched consent form override calculation.
    protocol BatchedConsentFormOverrideModifier {
        func describe() -> String
        func adjust(_ item: BatchedConsentFormOverride, value: Double) -> Double
    }

    final class BatchedConsentFormOverrideRateOffsetAdjuster: BatchedConsentFormOverrideModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: BatchedConsentFormOverride, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    final class MinimumBatchedConsentFormOverrideAdjuster: BatchedConsentFormOverrideModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedConsentFormOverride, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingBatchedConsentFormOverrideAdjuster: BatchedConsentFormOverrideModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedConsentFormOverride, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched consent form override steps in order and keeps a trace of each.
    final class BatchedConsentFormOverrideEngine {
        var steps: [any BatchedConsentFormOverrideModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedConsentFormOverrideModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedConsentFormOverride) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any BatchedConsentFormOverrideModifier = steps[index]
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

        func evaluateAll(_ items: [BatchedConsentFormOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedConsentFormOverrideEngine() -> BatchedConsentFormOverrideEngine {
        return BatchedConsentFormOverrideEngine(
            steps: [
                BatchedConsentFormOverrideRateOffsetAdjuster(weight: 0.19),
                MinimumBatchedConsentFormOverrideAdjuster(minimum: 1.4),
                RoundingBatchedConsentFormOverrideAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 54497.4
        )
    }
}
