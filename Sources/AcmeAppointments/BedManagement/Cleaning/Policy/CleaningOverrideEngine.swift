import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning override calculation.
    protocol CleaningOverrideStep {
        func describe() -> String
        func adjust(_ item: CleaningOverride, value: Double) -> Double
    }

    final class CapCleaningOverrideAdjuster: CleaningOverrideStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CleaningOverride, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCleaningOverrideAdjuster: CleaningOverrideStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningOverride, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CleaningOverrideQuantityOffsetAdjuster: CleaningOverrideStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CleaningOverride, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    /// Runs the cleaning override steps in order and keeps a trace of each.
    final class CleaningOverrideEngine {
        var steps: [any CleaningOverrideStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningOverrideStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CleaningOverride) -> Double {
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

        func evaluateAll(_ items: [CleaningOverride]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCleaningOverrideEngine() -> CleaningOverrideEngine {
        return CleaningOverrideEngine(
            steps: [
                CapCleaningOverrideAdjuster(cap: 27104.0),
                TieredCleaningOverrideAdjuster(
                    bounds: [1126.0, 4987.0, 5234.0, 9385.0],
                    rates: [0.92, 0.85, 0.81, 0.82]
                ),
                CleaningOverrideQuantityOffsetAdjuster(weight: 1.15),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 3900.1
        )
    }
}
