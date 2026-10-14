import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the global overtime baseline calculation.
    protocol GlobalOvertimeBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalOvertimeBaseline, value: Double) -> Double
    }

    final class TieredGlobalOvertimeBaselineAdjuster: GlobalOvertimeBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalOvertimeBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionGlobalOvertimeBaselineAdjuster: GlobalOvertimeBaselineAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: GlobalOvertimeBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingGlobalOvertimeBaselineAdjuster: GlobalOvertimeBaselineAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalOvertimeBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global overtime baseline steps in order and keeps a trace of each.
    final class GlobalOvertimeBaselineEngine {
        var steps: [any GlobalOvertimeBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalOvertimeBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalOvertimeBaseline) -> Double {
            var current = item.projectedExposure()
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

        func evaluateAll(_ items: [GlobalOvertimeBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalOvertimeBaselineEngine() -> GlobalOvertimeBaselineEngine {
        return GlobalOvertimeBaselineEngine(
            steps: [
                TieredGlobalOvertimeBaselineAdjuster(
                    bounds: [6356.0, 6612.0, 6939.0, 9595.0],
                    rates: [0.84, 0.83, 0.9, 0.98]
                ),
                RegionGlobalOvertimeBaselineAdjuster(factors: ["central": 0.85]),
                RoundingGlobalOvertimeBaselineAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 3625.1
        )
    }
}
