import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert quota calculation.
    protocol AlertQuotaStep {
        func describe() -> String
        func adjust(_ item: AlertQuota, value: Double) -> Double
    }

    final class MinimumAlertQuotaAdjuster: AlertQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapAlertQuotaAdjuster: AlertQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAlertQuotaAdjuster: AlertQuotaStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAlertQuotaAdjuster: AlertQuotaStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AlertQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class AlertQuotaMaximumOffsetAdjuster: AlertQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: AlertQuota, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    /// Runs the alert quota steps in order and keeps a trace of each.
    final class AlertQuotaEngine {
        var steps: [any AlertQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AlertQuota) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [AlertQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAlertQuotaEngine() -> AlertQuotaEngine {
        return AlertQuotaEngine(
            steps: [
                MinimumAlertQuotaAdjuster(minimum: 0.5),
                CapAlertQuotaAdjuster(cap: 20690.0),
                TieredAlertQuotaAdjuster(bounds: [641.0, 1880.0, 4439.0, 5563.0], rates: [1.14, 0.95, 0.94, 0.87]),
                RoundingAlertQuotaAdjuster(step: 0.1),
                AlertQuotaMaximumOffsetAdjuster(weight: 1.45),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 64922.5
        )
    }
}
