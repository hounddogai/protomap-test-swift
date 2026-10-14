import AcmePlatform
import Foundation

extension Labs {
    /// One step of the courier agreement calculation.
    protocol CourierAgreementFactor {
        func describe() -> String
        func adjust(_ item: CourierAgreement, value: Double) -> Double
    }

    final class MinimumCourierAgreementAdjuster: CourierAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CourierAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentCourierAgreementAdjuster: CourierAgreementFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CourierAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCourierAgreementAdjuster: CourierAgreementFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CourierAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitCourierAgreementAdjuster: CourierAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: CourierAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the courier agreement steps in order and keeps a trace of each.
    final class CourierAgreementEngine {
        var steps: [any CourierAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CourierAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CourierAgreement) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [CourierAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCourierAgreementEngine() -> CourierAgreementEngine {
        return CourierAgreementEngine(
            steps: [
                MinimumCourierAgreementAdjuster(minimum: 32.5),
                PercentCourierAgreementAdjuster(percent: 21.2),
                TieredCourierAgreementAdjuster(
                    bounds: [3462.0, 8547.0, 9189.0, 9681.0],
                    rates: [0.92, 0.87, 1.1, 0.83]
                ),
                UnitCourierAgreementAdjuster(factors: ["online": 1.17]),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 57093.5
        )
    }
}
