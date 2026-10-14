import AcmePlatform
import Foundation

extension Consent {
    /// One step of the consent form baseline calculation.
    protocol ConsentFormBaselineModifier {
        func describe() -> String
        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double
    }

    final class TieredConsentFormBaselineAdjuster: ConsentFormBaselineModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapConsentFormBaselineAdjuster: ConsentFormBaselineModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class ConsentFormBaselineFloorValueOffsetAdjuster: ConsentFormBaselineModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class NameConsentFormBaselineAdjuster: ConsentFormBaselineModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumConsentFormBaselineAdjuster: ConsentFormBaselineModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingConsentFormBaselineAdjuster: ConsentFormBaselineModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ConsentFormBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the consent form baseline steps in order and keeps a trace of each.
    final class ConsentFormBaselineEngine {
        var steps: [any ConsentFormBaselineModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ConsentFormBaselineModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ConsentFormBaseline) -> Double {
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

        func evaluateAll(_ items: [ConsentFormBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultConsentFormBaselineEngine() -> ConsentFormBaselineEngine {
        return ConsentFormBaselineEngine(
            steps: [
                TieredConsentFormBaselineAdjuster(
                    bounds: [2121.0, 5831.0, 6932.0, 7002.0],
                    rates: [1.2, 1.09, 0.91, 0.83]
                ),
                CapConsentFormBaselineAdjuster(cap: 23780.0),
                ConsentFormBaselineFloorValueOffsetAdjuster(weight: 0.41),
                NameConsentFormBaselineAdjuster(factors: ["south": 0.82, "east": 1.1]),
                MinimumConsentFormBaselineAdjuster(minimum: 41.1),
                RoundingConsentFormBaselineAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 24628.5
        )
    }
}
