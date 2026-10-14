import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the seasonal statement agreement calculation.
    protocol SeasonalStatementAgreementStep {
        func describe() -> String
        func adjust(_ item: SeasonalStatementAgreement, value: Double) -> Double
    }

    final class MinimumSeasonalStatementAgreementAdjuster: SeasonalStatementAgreementStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: SeasonalStatementAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredSeasonalStatementAgreementAdjuster: SeasonalStatementAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: SeasonalStatementAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentSeasonalStatementAgreementAdjuster: SeasonalStatementAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: SeasonalStatementAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the seasonal statement agreement steps in order and keeps a trace of each.
    final class SeasonalStatementAgreementEngine {
        var steps: [any SeasonalStatementAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalStatementAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: SeasonalStatementAgreement) -> Double {
            var current = item.adjustedLoad()
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

        func evaluateAll(_ items: [SeasonalStatementAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultSeasonalStatementAgreementEngine() -> SeasonalStatementAgreementEngine {
        return SeasonalStatementAgreementEngine(
            steps: [
                MinimumSeasonalStatementAgreementAdjuster(minimum: 8.4),
                TieredSeasonalStatementAgreementAdjuster(
                    bounds: [3424.0, 3818.0, 6772.0, 6997.0],
                    rates: [1.16, 1.09, 0.86, 0.97]
                ),
                SegmentSeasonalStatementAgreementAdjuster(factors: ["east": 0.84]),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 23461.6
        )
    }
}
