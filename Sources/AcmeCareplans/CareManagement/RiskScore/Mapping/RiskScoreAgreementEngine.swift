import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score agreement calculation.
    protocol RiskScoreAgreementModifier {
        func describe() -> String
        func adjust(_ item: RiskScoreAgreement, value: Double) -> Double
    }

    final class PercentRiskScoreAgreementAdjuster: RiskScoreAgreementModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumRiskScoreAgreementAdjuster: RiskScoreAgreementModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreAgreement, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRiskScoreAgreementAdjuster: RiskScoreAgreementModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RiskScoreAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRiskScoreAgreementAdjuster: RiskScoreAgreementModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the risk score agreement steps in order and keeps a trace of each.
    final class RiskScoreAgreementEngine {
        var steps: [any RiskScoreAgreementModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreAgreementModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RiskScoreAgreement) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreAgreementModifier = steps[index]
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

        func evaluateAll(_ items: [RiskScoreAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRiskScoreAgreementEngine() -> RiskScoreAgreementEngine {
        return RiskScoreAgreementEngine(
            steps: [
                PercentRiskScoreAgreementAdjuster(percent: 24.2),
                MinimumRiskScoreAgreementAdjuster(minimum: 6.4),
                TieredRiskScoreAgreementAdjuster(bounds: [3576.0, 7235.0, 8885.0], rates: [1.12, 0.84, 0.84]),
                RoundingRiskScoreAgreementAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 27285.1
        )
    }
}
