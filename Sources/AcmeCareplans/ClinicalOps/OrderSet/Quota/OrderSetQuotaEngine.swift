import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the order set quota calculation.
    protocol OrderSetQuotaStep {
        func describe() -> String
        func adjust(_ item: OrderSetQuota, value: Double) -> Double
    }

    final class RoundingOrderSetQuotaAdjuster: OrderSetQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: OrderSetQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapOrderSetQuotaAdjuster: OrderSetQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: OrderSetQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class OrderSetQuotaQuantityOffsetAdjuster: OrderSetQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: OrderSetQuota, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class CountryOrderSetQuotaAdjuster: OrderSetQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: OrderSetQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the order set quota steps in order and keeps a trace of each.
    final class OrderSetQuotaEngine {
        var steps: [any OrderSetQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any OrderSetQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: OrderSetQuota) -> Double {
            var current = item.netExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any OrderSetQuotaStep = steps[index]
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

        func evaluateAll(_ items: [OrderSetQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultOrderSetQuotaEngine() -> OrderSetQuotaEngine {
        return OrderSetQuotaEngine(
            steps: [
                RoundingOrderSetQuotaAdjuster(step: 1.0),
                CapOrderSetQuotaAdjuster(cap: 22062.0),
                OrderSetQuotaQuantityOffsetAdjuster(weight: 1.06),
                CountryOrderSetQuotaAdjuster(factors: ["north": 1.32, "retail": 1.09]),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 35153.8
        )
    }
}
