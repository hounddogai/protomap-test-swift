import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the discharge plan baseline calculation.
    protocol DischargePlanBaselineAdjuster {
        func describe() -> String
        func adjust(_ item: DischargePlanBaseline, value: Double) -> Double
    }

    final class CapDischargePlanBaselineAdjuster: DischargePlanBaselineAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DischargePlanBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredDischargePlanBaselineAdjuster: DischargePlanBaselineAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DischargePlanBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumDischargePlanBaselineAdjuster: DischargePlanBaselineAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DischargePlanBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the discharge plan baseline steps in order and keeps a trace of each.
    final class DischargePlanBaselineEngine {
        var steps: [any DischargePlanBaselineAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DischargePlanBaselineAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DischargePlanBaseline) -> Double {
            var current = item.netExposure()
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

        func evaluateAll(_ items: [DischargePlanBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDischargePlanBaselineEngine() -> DischargePlanBaselineEngine {
        return DischargePlanBaselineEngine(
            steps: [
                CapDischargePlanBaselineAdjuster(cap: 9647.0),
                TieredDischargePlanBaselineAdjuster(
                    bounds: [3991.0, 6523.0, 8656.0, 8818.0],
                    rates: [1.09, 0.86, 1.05, 1.18]
                ),
                MinimumDischargePlanBaselineAdjuster(minimum: 3.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 79731.1
        )
    }
}
