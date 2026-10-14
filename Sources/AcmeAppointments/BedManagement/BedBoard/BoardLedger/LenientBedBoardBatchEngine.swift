import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient bed board batch calculation.
    protocol LenientBedBoardBatchFactor {
        func describe() -> String
        func adjust(_ item: LenientBedBoardBatch, value: Double) -> Double
    }

    final class SourceLenientBedBoardBatchAdjuster: LenientBedBoardBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: LenientBedBoardBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientBedBoardBatchAdjuster: LenientBedBoardBatchFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientBedBoardBatch, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentLenientBedBoardBatchAdjuster: LenientBedBoardBatchFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientBedBoardBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the lenient bed board batch steps in order and keeps a trace of each.
    final class LenientBedBoardBatchEngine {
        var steps: [any LenientBedBoardBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientBedBoardBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientBedBoardBatch) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientBedBoardBatchFactor = steps[index]
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

        func evaluateAll(_ items: [LenientBedBoardBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientBedBoardBatchEngine() -> LenientBedBoardBatchEngine {
        return LenientBedBoardBatchEngine(
            steps: [
                SourceLenientBedBoardBatchAdjuster(factors: ["retail": 0.99]),
                CapLenientBedBoardBatchAdjuster(cap: 40537.0),
                PercentLenientBedBoardBatchAdjuster(percent: -8.8),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 83541.4
        )
    }
}
