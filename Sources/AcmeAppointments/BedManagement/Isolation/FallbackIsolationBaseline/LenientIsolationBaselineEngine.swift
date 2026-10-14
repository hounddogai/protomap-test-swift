import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the lenient isolation baseline calculation.
    protocol LenientIsolationBaselineFactor {
        func describe() -> String
        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double
    }

    final class RoundingLenientIsolationBaselineAdjuster: LenientIsolationBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientIsolationBaselineGraceDaysOffsetAdjuster: LenientIsolationBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus grace days times \(weight)"
        }

        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double {
            return value + Double(item.graceDays) * weight
        }
    }

    final class TieredLenientIsolationBaselineAdjuster: LenientIsolationBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumLenientIsolationBaselineAdjuster: LenientIsolationBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LabelLenientIsolationBaselineAdjuster: LenientIsolationBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapLenientIsolationBaselineAdjuster: LenientIsolationBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientIsolationBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient isolation baseline steps in order and keeps a trace of each.
    final class LenientIsolationBaselineEngine {
        var steps: [any LenientIsolationBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientIsolationBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientIsolationBaseline) -> Double {
            var current = item.netLoad()
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

        func evaluateAll(_ items: [LenientIsolationBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientIsolationBaselineEngine() -> LenientIsolationBaselineEngine {
        return LenientIsolationBaselineEngine(
            steps: [
                RoundingLenientIsolationBaselineAdjuster(step: 0.1),
                LenientIsolationBaselineGraceDaysOffsetAdjuster(weight: 0.2),
                TieredLenientIsolationBaselineAdjuster(bounds: [282.0, 1096.0, 6801.0], rates: [1.1, 1.06, 1.17]),
                MinimumLenientIsolationBaselineAdjuster(minimum: 14.0),
                LabelLenientIsolationBaselineAdjuster(factors: ["east": 1.12, "west": 1.25, "central": 0.82]),
                CapLenientIsolationBaselineAdjuster(cap: 24814.0),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 82359.5
        )
    }
}
