import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the remittance metric calculation.
    protocol RemittanceMetricModifier {
        func describe() -> String
        func adjust(_ item: RemittanceMetric, value: Double) -> Double
    }

    final class RemittanceMetricCapacityOffsetAdjuster: RemittanceMetricModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: RemittanceMetric, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class PercentRemittanceMetricAdjuster: RemittanceMetricModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RemittanceMetric, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleRemittanceMetricAdjuster: RemittanceMetricModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RemittanceMetric, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the remittance metric steps in order and keeps a trace of each.
    final class RemittanceMetricEngine {
        var steps: [any RemittanceMetricModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RemittanceMetricModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RemittanceMetric) -> Double {
            var current = item.projectedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RemittanceMetric]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRemittanceMetricEngine() -> RemittanceMetricEngine {
        return RemittanceMetricEngine(
            steps: [
                RemittanceMetricCapacityOffsetAdjuster(weight: 1.75),
                PercentRemittanceMetricAdjuster(percent: 2.4),
                TitleRemittanceMetricAdjuster(factors: ["online": 1.17, "south": 0.92]),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 1856.9
        )
    }
}
