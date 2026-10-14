import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the capped cleaning agreement calculation.
    protocol CappedCleaningAgreementStep {
        func describe() -> String
        func adjust(_ item: CappedCleaningAgreement, value: Double) -> Double
    }

    final class CappedCleaningAgreementStartsAtOffsetAdjuster: CappedCleaningAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: CappedCleaningAgreement, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class CategoryCappedCleaningAgreementAdjuster: CappedCleaningAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: CappedCleaningAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCappedCleaningAgreementAdjuster: CappedCleaningAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCleaningAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedCleaningAgreementAdjuster: CappedCleaningAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCleaningAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCappedCleaningAgreementAdjuster: CappedCleaningAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedCleaningAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the capped cleaning agreement steps in order and keeps a trace of each.
    final class CappedCleaningAgreementEngine {
        var steps: [any CappedCleaningAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCleaningAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedCleaningAgreement) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [CappedCleaningAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedCleaningAgreementEngine() -> CappedCleaningAgreementEngine {
        return CappedCleaningAgreementEngine(
            steps: [
                CappedCleaningAgreementStartsAtOffsetAdjuster(weight: 0.33),
                CategoryCappedCleaningAgreementAdjuster(factors: ["central": 1.27]),
                CapCappedCleaningAgreementAdjuster(cap: 29418.0),
                TieredCappedCleaningAgreementAdjuster(bounds: [2057.0, 5780.0], rates: [1.18, 0.85]),
                PercentCappedCleaningAgreementAdjuster(percent: -16.0),
            ],
            trace: [],
            floor: 2.7,
            ceiling: 34603.0
        )
    }
}
