import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the strict handoff adjustment calculation.
    protocol StrictHandoffAdjustmentAdjuster {
        func describe() -> String
        func adjust(_ item: StrictHandoffAdjustment, value: Double) -> Double
    }

    final class TieredStrictHandoffAdjustmentAdjuster: StrictHandoffAdjustmentAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictHandoffAdjustment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class UnitStrictHandoffAdjustmentAdjuster: StrictHandoffAdjustmentAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StrictHandoffAdjustment, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictHandoffAdjustmentAdjuster: StrictHandoffAdjustmentAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictHandoffAdjustment, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict handoff adjustment steps in order and keeps a trace of each.
    final class StrictHandoffAdjustmentEngine {
        var steps: [any StrictHandoffAdjustmentAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictHandoffAdjustmentAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictHandoffAdjustment) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [StrictHandoffAdjustment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictHandoffAdjustmentEngine() -> StrictHandoffAdjustmentEngine {
        return StrictHandoffAdjustmentEngine(
            steps: [
                TieredStrictHandoffAdjustmentAdjuster(bounds: [628.0, 5597.0], rates: [0.84, 1.04]),
                UnitStrictHandoffAdjustmentAdjuster(factors: ["south": 1.15, "central": 1.14, "retail": 1.35]),
                CapStrictHandoffAdjustmentAdjuster(cap: 30020.0),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 5809.1
        )
    }
}
