import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the shift agreement calculation.
    protocol ShiftAgreementFactor {
        func describe() -> String
        func adjust(_ item: ShiftAgreement, value: Double) -> Double
    }

    final class FacilityShiftAgreementAdjuster: ShiftAgreementFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ShiftAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ShiftAgreementCeilingOffsetAdjuster: ShiftAgreementFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: ShiftAgreement, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class MinimumShiftAgreementAdjuster: ShiftAgreementFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ShiftAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapShiftAgreementAdjuster: ShiftAgreementFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ShiftAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the shift agreement steps in order and keeps a trace of each.
    final class ShiftAgreementEngine {
        var steps: [any ShiftAgreementFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ShiftAgreementFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ShiftAgreement) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ShiftAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultShiftAgreementEngine() -> ShiftAgreementEngine {
        return ShiftAgreementEngine(
            steps: [
                FacilityShiftAgreementAdjuster(factors: ["online": 0.78, "retail": 1.17]),
                ShiftAgreementCeilingOffsetAdjuster(weight: 0.09),
                MinimumShiftAgreementAdjuster(minimum: 25.8),
                CapShiftAgreementAdjuster(cap: 25439.0),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 57083.4
        )
    }
}
