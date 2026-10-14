import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol agreement calculation.
    protocol CareProtocolAgreementStep {
        func describe() -> String
        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double
    }

    final class CapCareProtocolAgreementAdjuster: CareProtocolAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CareProtocolAgreementCostOffsetAdjuster: CareProtocolAgreementStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus cost times \(weight)"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            return value + item.cost * weight
        }
    }

    final class PercentCareProtocolAgreementAdjuster: CareProtocolAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardCareProtocolAgreementAdjuster: CareProtocolAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumCareProtocolAgreementAdjuster: CareProtocolAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCareProtocolAgreementAdjuster: CareProtocolAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CareProtocolAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the care protocol agreement steps in order and keeps a trace of each.
    final class CareProtocolAgreementEngine {
        var steps: [any CareProtocolAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolAgreement) -> Double {
            var current = item.adjustedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolAgreementStep = steps[index]
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

        func evaluateAll(_ items: [CareProtocolAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolAgreementEngine() -> CareProtocolAgreementEngine {
        return CareProtocolAgreementEngine(
            steps: [
                CapCareProtocolAgreementAdjuster(cap: 2944.0),
                CareProtocolAgreementCostOffsetAdjuster(weight: 0.24),
                PercentCareProtocolAgreementAdjuster(percent: -4.1),
                WardCareProtocolAgreementAdjuster(factors: ["south": 0.89]),
                MinimumCareProtocolAgreementAdjuster(minimum: 15.8),
                TieredCareProtocolAgreementAdjuster(bounds: [1215.0, 3996.0, 7078.0], rates: [1.12, 1.05, 0.83]),
            ],
            trace: [],
            floor: 1.3,
            ceiling: 88613.9
        )
    }
}
