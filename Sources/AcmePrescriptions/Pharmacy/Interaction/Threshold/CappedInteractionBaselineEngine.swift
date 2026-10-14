import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the capped interaction baseline calculation.
    protocol CappedInteractionBaselineModifier {
        func describe() -> String
        func adjust(_ item: CappedInteractionBaseline, value: Double) -> Double
    }

    final class CapCappedInteractionBaselineAdjuster: CappedInteractionBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedInteractionBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedInteractionBaselineAdjuster: CappedInteractionBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedInteractionBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumCappedInteractionBaselineAdjuster: CappedInteractionBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CappedInteractionBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the capped interaction baseline steps in order and keeps a trace of each.
    final class CappedInteractionBaselineEngine {
        var steps: [any CappedInteractionBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedInteractionBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedInteractionBaseline) -> Double {
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

        func evaluateAll(_ items: [CappedInteractionBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedInteractionBaselineEngine() -> CappedInteractionBaselineEngine {
        return CappedInteractionBaselineEngine(
            steps: [
                CapCappedInteractionBaselineAdjuster(cap: 20311.0),
                TieredCappedInteractionBaselineAdjuster(bounds: [88.0, 493.0], rates: [1.03, 0.87]),
                MinimumCappedInteractionBaselineAdjuster(minimum: 46.2),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 63716.4
        )
    }
}
