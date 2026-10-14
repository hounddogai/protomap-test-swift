import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the lenient program baseline calculation.
    protocol LenientProgramBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: LenientProgramBaseline, value: Double) -> Double
    }

    final class RoundingLenientProgramBaselineAdjuster: LenientProgramBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProgramBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumLenientProgramBaselineAdjuster: LenientProgramBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProgramBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredLenientProgramBaselineAdjuster: LenientProgramBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: LenientProgramBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapLenientProgramBaselineAdjuster: LenientProgramBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProgramBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelLenientProgramBaselineAdjuster: LenientProgramBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: LenientProgramBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the lenient program baseline steps in order and keeps a trace of each.
    final class LenientProgramBaselineEngine {
        var steps: [any LenientProgramBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProgramBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LenientProgramBaseline) -> Double {
            var current = item.projectedLoad()
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

        func evaluateAll(_ items: [LenientProgramBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLenientProgramBaselineEngine() -> LenientProgramBaselineEngine {
        return LenientProgramBaselineEngine(
            steps: [
                RoundingLenientProgramBaselineAdjuster(step: 1.0),
                MinimumLenientProgramBaselineAdjuster(minimum: 42.8),
                TieredLenientProgramBaselineAdjuster(
                    bounds: [957.0, 2009.0, 2425.0, 7788.0],
                    rates: [1.11, 1.18, 0.99, 0.92]
                ),
                CapLenientProgramBaselineAdjuster(cap: 3276.0),
                LabelLenientProgramBaselineAdjuster(factors: ["central": 0.73, "west": 1.14, "online": 0.74]),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 4273.6
        )
    }
}
