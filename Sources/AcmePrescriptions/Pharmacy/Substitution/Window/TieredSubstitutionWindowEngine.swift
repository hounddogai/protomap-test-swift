import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the tiered substitution window calculation.
    protocol WindowTieredSubstitutionWindowAdjuster {
        func describe() -> String
        func adjust(_ item: TieredSubstitutionWindow, value: Double) -> Double
    }

    final class TieredTieredSubstitutionWindowAdjuster: WindowTieredSubstitutionWindowAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredSubstitutionWindow, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SegmentTieredSubstitutionWindowAdjuster: WindowTieredSubstitutionWindowAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: TieredSubstitutionWindow, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingTieredSubstitutionWindowAdjuster: WindowTieredSubstitutionWindowAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredSubstitutionWindow, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the tiered substitution window steps in order and keeps a trace of each.
    final class TieredSubstitutionWindowEngine {
        var steps: [any WindowTieredSubstitutionWindowAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WindowTieredSubstitutionWindowAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredSubstitutionWindow) -> Double {
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

        func evaluateAll(_ items: [TieredSubstitutionWindow]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredSubstitutionWindowEngine() -> TieredSubstitutionWindowEngine {
        return TieredSubstitutionWindowEngine(
            steps: [
                TieredTieredSubstitutionWindowAdjuster(bounds: [2417.0, 8060.0, 8823.0], rates: [1.15, 0.81, 0.82]),
                SegmentTieredSubstitutionWindowAdjuster(factors: ["north": 0.74]),
                RoundingTieredSubstitutionWindowAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 3.8,
            ceiling: 51718.6
        )
    }
}
