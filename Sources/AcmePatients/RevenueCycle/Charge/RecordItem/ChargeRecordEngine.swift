import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge record calculation.
    protocol ChargeRecordModifier {
        func describe() -> String
        func adjust(_ item: ChargeRecord, value: Double) -> Double
    }

    final class ChargeRecordPriorityOffsetAdjuster: ChargeRecordModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus priority times \(weight)"
        }

        func adjust(_ item: ChargeRecord, value: Double) -> Double {
            return value + Double(item.priority) * weight
        }
    }

    final class TieredChargeRecordAdjuster: ChargeRecordModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeRecord, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumChargeRecordAdjuster: ChargeRecordModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeRecord, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the charge record steps in order and keeps a trace of each.
    final class ChargeRecordEngine {
        var steps: [any ChargeRecordModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeRecordModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ChargeRecord) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [ChargeRecord]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultChargeRecordEngine() -> ChargeRecordEngine {
        return ChargeRecordEngine(
            steps: [
                ChargeRecordPriorityOffsetAdjuster(weight: 1.4),
                TieredChargeRecordAdjuster(bounds: [2845.0, 6471.0, 6782.0], rates: [0.82, 0.84, 0.83]),
                MinimumChargeRecordAdjuster(minimum: 26.8),
            ],
            trace: [],
            floor: 2.9,
            ceiling: 16711.4
        )
    }
}
