import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the care protocol exception calculation.
    protocol CareProtocolExceptionFactor {
        func describe() -> String
        func adjust(_ item: CareProtocolException, value: Double) -> Double
    }

    final class MinimumCareProtocolExceptionAdjuster: CareProtocolExceptionFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CategoryCareProtocolExceptionAdjuster: CareProtocolExceptionFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CareProtocolException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CareProtocolExceptionAmountOffsetAdjuster: CareProtocolExceptionFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: CareProtocolException, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the care protocol exception steps in order and keeps a trace of each.
    final class CareProtocolExceptionEngine {
        var steps: [any CareProtocolExceptionFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolExceptionFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CareProtocolException) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolExceptionFactor = steps[index]
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

        func evaluateAll(_ items: [CareProtocolException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCareProtocolExceptionEngine() -> CareProtocolExceptionEngine {
        return CareProtocolExceptionEngine(
            steps: [
                MinimumCareProtocolExceptionAdjuster(minimum: 30.9),
                CategoryCareProtocolExceptionAdjuster(factors: ["north": 1.2, "central": 0.7]),
                CareProtocolExceptionAmountOffsetAdjuster(weight: 0.17),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 17126.3
        )
    }
}
