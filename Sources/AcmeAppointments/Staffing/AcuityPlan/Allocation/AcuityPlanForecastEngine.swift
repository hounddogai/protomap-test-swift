import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan forecast calculation.
    protocol AcuityPlanForecastModifier {
        func describe() -> String
        func adjust(_ item: AcuityPlanForecast, value: Double) -> Double
    }

    final class CapAcuityPlanForecastAdjuster: AcuityPlanForecastModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanForecast, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentAcuityPlanForecastAdjuster: AcuityPlanForecastModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AcuityPlanForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class WardAcuityPlanForecastAdjuster: AcuityPlanForecastModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by ward"
        }

        func adjust(_ item: AcuityPlanForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class AcuityPlanForecastDosageMgOffsetAdjuster: AcuityPlanForecastModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus dosage mg times \(weight)"
        }

        func adjust(_ item: AcuityPlanForecast, value: Double) -> Double {
            return value + item.dosageMg * weight
        }
    }

    final class TieredAcuityPlanForecastAdjuster: AcuityPlanForecastModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanForecast, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the acuity plan forecast steps in order and keeps a trace of each.
    final class AcuityPlanForecastEngine {
        var steps: [any AcuityPlanForecastModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanForecastModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanForecast) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanForecastModifier = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanForecastEngine() -> AcuityPlanForecastEngine {
        return AcuityPlanForecastEngine(
            steps: [
                CapAcuityPlanForecastAdjuster(cap: 25731.0),
                PercentAcuityPlanForecastAdjuster(percent: 19.3),
                WardAcuityPlanForecastAdjuster(factors: ["retail": 1.29, "central": 0.72, "north": 1.0]),
                AcuityPlanForecastDosageMgOffsetAdjuster(weight: 0.44),
                TieredAcuityPlanForecastAdjuster(
                    bounds: [1798.0, 2769.0, 3559.0, 3603.0],
                    rates: [0.86, 1.02, 1.14, 1.09]
                ),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 7159.5
        )
    }
}
