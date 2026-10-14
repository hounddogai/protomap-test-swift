import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form batch calculation.
    protocol ConsentFormBatchFactor {
        func describe() -> String
        func adjust(_ item: ConsentFormBatch, value: Double) -> Double
    }

    final class TieredConsentFormBatchAdjuster: ConsentFormBatchFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CountryConsentFormBatchAdjuster: ConsentFormBatchFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: ConsentFormBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ConsentFormBatchDosageMgOffsetAdjuster: ConsentFormBatchFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: ConsentFormBatch, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    /// Runs the consent form batch steps in order and keeps a trace of each.
    final class ConsentFormBatchEngine {
        var steps: [any ConsentFormBatchFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormBatchFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ConsentFormBatch) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ConsentFormBatchFactor = steps[index]
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

        func evaluateAll(_ items: [ConsentFormBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultConsentFormBatchEngine() -> ConsentFormBatchEngine {
        return ConsentFormBatchEngine(
            steps: [
                TieredConsentFormBatchAdjuster(bounds: [365.0, 7551.0, 8465.0], rates: [1.03, 0.89, 0.89]),
                CountryConsentFormBatchAdjuster(factors: ["central": 1.31]),
                ConsentFormBatchDosageMgOffsetAdjuster(weight: 1.25),
            ],
            trace: [],
            floor: 3.2,
            ceiling: 43150.0
        )
    }
}
