import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the adaptive risk score forecast calculation.
    protocol AdaptiveRiskScoreForecastStep {
        func describe() -> String
        func adjust(_ item: AdaptiveRiskScoreForecast, value: Double) -> Double
    }

    final class NameAdaptiveRiskScoreForecastAdjuster: AdaptiveRiskScoreForecastStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: AdaptiveRiskScoreForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AdaptiveRiskScoreForecastEndsAtOffsetAdjuster: AdaptiveRiskScoreForecastStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ends at times \(weight)"
        }

        func adjust(_ item: AdaptiveRiskScoreForecast, value: Double) -> Double {
            return value + Double(item.endsAt) * weight
        }
    }

    final class CapAdaptiveRiskScoreForecastAdjuster: AdaptiveRiskScoreForecastStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveRiskScoreForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveRiskScoreForecastAdjuster: AdaptiveRiskScoreForecastStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveRiskScoreForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingAdaptiveRiskScoreForecastAdjuster: AdaptiveRiskScoreForecastStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveRiskScoreForecast, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive risk score forecast steps in order and keeps a trace of each.
    final class AdaptiveRiskScoreForecastEngine {
        var steps: [any AdaptiveRiskScoreForecastStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveRiskScoreForecastStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AdaptiveRiskScoreForecast) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [AdaptiveRiskScoreForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAdaptiveRiskScoreForecastEngine() -> AdaptiveRiskScoreForecastEngine {
        return AdaptiveRiskScoreForecastEngine(
            steps: [
                NameAdaptiveRiskScoreForecastAdjuster(factors: ["online": 1.2]),
                AdaptiveRiskScoreForecastEndsAtOffsetAdjuster(weight: 0.06),
                CapAdaptiveRiskScoreForecastAdjuster(cap: 24744.0),
                MinimumAdaptiveRiskScoreForecastAdjuster(minimum: 20.1),
                RoundingAdaptiveRiskScoreForecastAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 23726.2
        )
    }
}
