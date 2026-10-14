import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global acuity plan forecast calculation.
    protocol GlobalAcuityPlanForecastAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalAcuityPlanForecast, value: Double) -> Double
    }

    final class LocaleGlobalAcuityPlanForecastAdjuster: GlobalAcuityPlanForecastAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: GlobalAcuityPlanForecast, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class GlobalAcuityPlanForecastVisitMinutesOffsetAdjuster: GlobalAcuityPlanForecastAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus visit minutes times \(weight)"
        }

        func adjust(_ item: GlobalAcuityPlanForecast, value: Double) -> Double {
            return value + Double(item.visitMinutes) * weight
        }
    }

    final class PercentGlobalAcuityPlanForecastAdjuster: GlobalAcuityPlanForecastAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalAcuityPlanForecast, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalAcuityPlanForecastAdjuster: GlobalAcuityPlanForecastAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalAcuityPlanForecast, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the global acuity plan forecast steps in order and keeps a trace of each.
    final class GlobalAcuityPlanForecastEngine {
        var steps: [any GlobalAcuityPlanForecastAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalAcuityPlanForecastAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalAcuityPlanForecast) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalAcuityPlanForecastAdjuster = steps[index]
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

        func evaluateAll(_ items: [GlobalAcuityPlanForecast]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalAcuityPlanForecastEngine() -> GlobalAcuityPlanForecastEngine {
        return GlobalAcuityPlanForecastEngine(
            steps: [
                LocaleGlobalAcuityPlanForecastAdjuster(factors: ["online": 1.06]),
                GlobalAcuityPlanForecastVisitMinutesOffsetAdjuster(weight: 1.27),
                PercentGlobalAcuityPlanForecastAdjuster(percent: -18.4),
                MinimumGlobalAcuityPlanForecastAdjuster(minimum: 43.2),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 11819.0
        )
    }
}
