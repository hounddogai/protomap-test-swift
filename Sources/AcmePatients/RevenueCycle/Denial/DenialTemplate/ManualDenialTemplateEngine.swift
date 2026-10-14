import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the manual denial template calculation.
    protocol ManualDenialTemplateModifier {
        func describe() -> String
        func adjust(_ item: ManualDenialTemplate, value: Double) -> Double
    }

    final class PercentManualDenialTemplateAdjuster: ManualDenialTemplateModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualDenialTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredManualDenialTemplateAdjuster: ManualDenialTemplateModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualDenialTemplate, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualDenialTemplateAdjuster: ManualDenialTemplateModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualDenialTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the manual denial template steps in order and keeps a trace of each.
    final class ManualDenialTemplateEngine {
        var steps: [any ManualDenialTemplateModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualDenialTemplateModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ManualDenialTemplate) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [ManualDenialTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultManualDenialTemplateEngine() -> ManualDenialTemplateEngine {
        return ManualDenialTemplateEngine(
            steps: [
                PercentManualDenialTemplateAdjuster(percent: -10.2),
                TieredManualDenialTemplateAdjuster(bounds: [7263.0, 7511.0], rates: [1.03, 0.85]),
                MinimumManualDenialTemplateAdjuster(minimum: 11.8),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 43985.1
        )
    }
}
