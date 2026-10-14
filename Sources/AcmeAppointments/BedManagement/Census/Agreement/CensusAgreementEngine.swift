import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the census agreement calculation.
    protocol CensusAgreementStep {
        func describe() -> String
        func adjust(_ item: CensusAgreement, value: Double) -> Double
    }

    final class SourceCensusAgreementAdjuster: CensusAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: CensusAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredCensusAgreementAdjuster: CensusAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CensusAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentCensusAgreementAdjuster: CensusAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CensusAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the census agreement steps in order and keeps a trace of each.
    final class CensusAgreementEngine {
        var steps: [any CensusAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CensusAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CensusAgreement) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any CensusAgreementStep = steps[index]
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

        func evaluateAll(_ items: [CensusAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCensusAgreementEngine() -> CensusAgreementEngine {
        return CensusAgreementEngine(
            steps: [
                SourceCensusAgreementAdjuster(factors: ["retail": 1.09, "south": 0.74]),
                TieredCensusAgreementAdjuster(bounds: [7877.0, 8527.0], rates: [0.81, 0.9]),
                PercentCensusAgreementAdjuster(percent: -18.4),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 23046.2
        )
    }
}
