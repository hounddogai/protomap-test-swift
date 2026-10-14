import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation batch calculation.
    protocol RevocationBatchModifier {
        func describe() -> String
        func adjust(_ item: RevocationBatch, value: Double) -> Double
    }

    final class LabelRevocationBatchAdjuster: RevocationBatchModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: RevocationBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RevocationBatchScoreOffsetAdjuster: RevocationBatchModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: RevocationBatch, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class CapRevocationBatchAdjuster: RevocationBatchModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the revocation batch steps in order and keeps a trace of each.
    final class RevocationBatchEngine {
        var steps: [any RevocationBatchModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationBatchModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RevocationBatch) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RevocationBatchModifier = steps[index]
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

        func evaluateAll(_ items: [RevocationBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRevocationBatchEngine() -> RevocationBatchEngine {
        return RevocationBatchEngine(
            steps: [
                LabelRevocationBatchAdjuster(factors: ["east": 0.98, "north": 1.33, "retail": 1.02]),
                RevocationBatchScoreOffsetAdjuster(weight: 1.91),
                CapRevocationBatchAdjuster(cap: 17695.0),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 42623.8
        )
    }
}
