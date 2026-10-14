import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the regional formulary cycle calculation.
    protocol RegionalFormularyCycleModifier {
        func describe() -> String
        func adjust(_ item: RegionalFormularyCycle, value: Double) -> Double
    }

    final class PercentRegionalFormularyCycleAdjuster: RegionalFormularyCycleModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalFormularyCycle, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingRegionalFormularyCycleAdjuster: RegionalFormularyCycleModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalFormularyCycle, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumRegionalFormularyCycleAdjuster: RegionalFormularyCycleModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalFormularyCycle, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the regional formulary cycle steps in order and keeps a trace of each.
    final class RegionalFormularyCycleEngine {
        var steps: [any RegionalFormularyCycleModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalFormularyCycleModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalFormularyCycle) -> Double {
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

        func evaluateAll(_ items: [RegionalFormularyCycle]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalFormularyCycleEngine() -> RegionalFormularyCycleEngine {
        return RegionalFormularyCycleEngine(
            steps: [
                PercentRegionalFormularyCycleAdjuster(percent: -13.8),
                RoundingRegionalFormularyCycleAdjuster(step: 1.0),
                MinimumRegionalFormularyCycleAdjuster(minimum: 27.7),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 78477.7
        )
    }
}
