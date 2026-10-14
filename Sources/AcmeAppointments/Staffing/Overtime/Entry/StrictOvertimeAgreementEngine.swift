import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the strict overtime agreement calculation.
    protocol StrictOvertimeAgreementAdjuster {
        func describe() -> String
        func adjust(_ item: StrictOvertimeAgreement, value: Double) -> Double
    }

    final class StrictOvertimeAgreementRetriesOffsetAdjuster: StrictOvertimeAgreementAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: StrictOvertimeAgreement, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class RoundingStrictOvertimeAgreementAdjuster: StrictOvertimeAgreementAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictOvertimeAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredStrictOvertimeAgreementAdjuster: StrictOvertimeAgreementAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictOvertimeAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStrictOvertimeAgreementAdjuster: StrictOvertimeAgreementAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictOvertimeAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict overtime agreement steps in order and keeps a trace of each.
    final class StrictOvertimeAgreementEngine {
        var steps: [any StrictOvertimeAgreementAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictOvertimeAgreementAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictOvertimeAgreement) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [StrictOvertimeAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictOvertimeAgreementEngine() -> StrictOvertimeAgreementEngine {
        return StrictOvertimeAgreementEngine(
            steps: [
                StrictOvertimeAgreementRetriesOffsetAdjuster(weight: 1.97),
                RoundingStrictOvertimeAgreementAdjuster(step: 0.5),
                TieredStrictOvertimeAgreementAdjuster(bounds: [1896.0, 5725.0], rates: [0.95, 1.04]),
                MinimumStrictOvertimeAgreementAdjuster(minimum: 47.0),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 97651.2
        )
    }
}
