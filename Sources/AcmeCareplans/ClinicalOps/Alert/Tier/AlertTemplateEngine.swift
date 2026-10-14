import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the alert template calculation.
    protocol AlertTemplateModifier {
        func describe() -> String
        func adjust(_ item: AlertTemplate, value: Double) -> Double
    }

    final class AlertTemplateRefillsOffsetAdjuster: AlertTemplateModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: AlertTemplate, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class TieredAlertTemplateAdjuster: AlertTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AlertTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumAlertTemplateAdjuster: AlertTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AlertTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LocaleAlertTemplateAdjuster: AlertTemplateModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: AlertTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAlertTemplateAdjuster: AlertTemplateModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AlertTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the alert template steps in order and keeps a trace of each.
    final class AlertTemplateEngine {
        var steps: [any AlertTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AlertTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: AlertTemplate) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AlertTemplateModifier = steps[index]
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

        func evaluateAll(_ items: [AlertTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultAlertTemplateEngine() -> AlertTemplateEngine {
        return AlertTemplateEngine(
            steps: [
                AlertTemplateRefillsOffsetAdjuster(weight: 0.68),
                TieredAlertTemplateAdjuster(bounds: [1857.0, 6224.0], rates: [1.15, 0.92]),
                MinimumAlertTemplateAdjuster(minimum: 0.8),
                LocaleAlertTemplateAdjuster(factors: ["south": 0.92, "east": 0.89, "north": 1.16]),
                CapAlertTemplateAdjuster(cap: 4017.0),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 64084.6
        )
    }
}
