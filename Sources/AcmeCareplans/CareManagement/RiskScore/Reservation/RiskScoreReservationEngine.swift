import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the risk score reservation calculation.
    protocol RiskScoreReservationStep {
        func describe() -> String
        func adjust(_ item: RiskScoreReservation, value: Double) -> Double
    }

    final class PercentRiskScoreReservationAdjuster: RiskScoreReservationStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RiskScoreReservation, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRiskScoreReservationAdjuster: RiskScoreReservationStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RiskScoreReservation, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryRiskScoreReservationAdjuster: RiskScoreReservationStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: RiskScoreReservation, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RiskScoreReservationQuantityOffsetAdjuster: RiskScoreReservationStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: RiskScoreReservation, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class MinimumRiskScoreReservationAdjuster: RiskScoreReservationStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RiskScoreReservation, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the risk score reservation steps in order and keeps a trace of each.
    final class RiskScoreReservationEngine {
        var steps: [any RiskScoreReservationStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RiskScoreReservationStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RiskScoreReservation) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RiskScoreReservationStep = steps[index]
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

        func evaluateAll(_ items: [RiskScoreReservation]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRiskScoreReservationEngine() -> RiskScoreReservationEngine {
        return RiskScoreReservationEngine(
            steps: [
                PercentRiskScoreReservationAdjuster(percent: -12.0),
                RoundingRiskScoreReservationAdjuster(step: 0.25),
                CountryRiskScoreReservationAdjuster(factors: ["north": 1.09]),
                RiskScoreReservationQuantityOffsetAdjuster(weight: 1.46),
                MinimumRiskScoreReservationAdjuster(minimum: 12.3),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 83812.2
        )
    }
}
