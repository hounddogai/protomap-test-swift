import AcmePlatform
import Foundation

extension Consent {
    /// One step of the pending language window calculation.
    protocol PendingLanguageWindowStep {
        func describe() -> String
        func adjust(_ item: PendingLanguageWindow, value: Double) -> Double
    }

    final class PercentPendingLanguageWindowAdjuster: PendingLanguageWindowStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingLanguageWindow, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocalePendingLanguageWindowAdjuster: PendingLanguageWindowStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: PendingLanguageWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingPendingLanguageWindowAdjuster: PendingLanguageWindowStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingLanguageWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingLanguageWindowAdjuster: PendingLanguageWindowStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingLanguageWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending language window steps in order and keeps a trace of each.
    final class PendingLanguageWindowEngine {
        var steps: [any PendingLanguageWindowStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingLanguageWindowStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingLanguageWindow) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [PendingLanguageWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingLanguageWindowEngine() -> PendingLanguageWindowEngine {
        return PendingLanguageWindowEngine(
            steps: [
                PercentPendingLanguageWindowAdjuster(percent: 16.1),
                LocalePendingLanguageWindowAdjuster(factors: ["west": 0.85]),
                RoundingPendingLanguageWindowAdjuster(step: 1.0),
                TieredPendingLanguageWindowAdjuster(bounds: [1980.0, 2233.0], rates: [1.11, 1.15]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 27980.1
        )
    }
}
