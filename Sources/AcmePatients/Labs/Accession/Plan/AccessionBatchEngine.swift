import AcmePlatform
import Foundation

extension Labs {
    /// One step of the accession batch calculation.
    protocol AccessionBatchAdjuster {
        func describe() -> String
        func adjust(_ item: AccessionBatch, value: Double) -> Double
    }

    final class TitleAccessionBatchAdjuster: AccessionBatchAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: AccessionBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumAccessionBatchAdjuster: AccessionBatchAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AccessionBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentAccessionBatchAdjuster: AccessionBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AccessionBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the accession batch steps in order and keeps a trace of each.
    final class AccessionBatchEngine {
        var steps: [any AccessionBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AccessionBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AccessionBatch) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any AccessionBatchAdjuster = steps[index]
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

        func evaluateAll(_ items: [AccessionBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAccessionBatchEngine() -> AccessionBatchEngine {
        return AccessionBatchEngine(
            steps: [
                TitleAccessionBatchAdjuster(factors: ["south": 1.0]),
                MinimumAccessionBatchAdjuster(minimum: 27.3),
                PercentAccessionBatchAdjuster(percent: 10.4),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 50396.4
        )
    }
}
