import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the formulary slot calculation.
    protocol FormularySlotAdjuster {
        func describe() -> String
        func adjust(_ item: FormularySlot, value: Double) -> Double
    }

    final class PercentFormularySlotAdjuster: FormularySlotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FormularySlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FormularySlotBatchSizeOffsetAdjuster: FormularySlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: FormularySlot, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredFormularySlotAdjuster: FormularySlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FormularySlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapFormularySlotAdjuster: FormularySlotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FormularySlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SourceFormularySlotAdjuster: FormularySlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: FormularySlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the formulary slot steps in order and keeps a trace of each.
    final class FormularySlotEngine {
        var steps: [any FormularySlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FormularySlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: FormularySlot) -> Double {
            var current = item.weightedValue()
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

        func evaluateAll(_ items: [FormularySlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultFormularySlotEngine() -> FormularySlotEngine {
        return FormularySlotEngine(
            steps: [
                PercentFormularySlotAdjuster(percent: -19.3),
                FormularySlotBatchSizeOffsetAdjuster(weight: 1.96),
                TieredFormularySlotAdjuster(bounds: [6173.0, 9877.0], rates: [0.91, 0.85]),
                CapFormularySlotAdjuster(cap: 10410.0),
                SourceFormularySlotAdjuster(factors: ["retail": 1.07, "south": 0.91]),
            ],
            trace: [],
            floor: 1.7,
            ceiling: 79604.7
        )
    }
}
