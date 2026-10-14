import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the primary handoff slot calculation.
    protocol PrimaryHandoffSlotAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryHandoffSlot, value: Double) -> Double
    }

    final class RoundingPrimaryHandoffSlotAdjuster: PrimaryHandoffSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryHandoffSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPrimaryHandoffSlotAdjuster: PrimaryHandoffSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryHandoffSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PrimaryHandoffSlotRefillsOffsetAdjuster: PrimaryHandoffSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: PrimaryHandoffSlot, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the primary handoff slot steps in order and keeps a trace of each.
    final class PrimaryHandoffSlotEngine {
        var steps: [any PrimaryHandoffSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryHandoffSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: PrimaryHandoffSlot) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [PrimaryHandoffSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultPrimaryHandoffSlotEngine() -> PrimaryHandoffSlotEngine {
        return PrimaryHandoffSlotEngine(
            steps: [
                RoundingPrimaryHandoffSlotAdjuster(step: 1.0),
                TieredPrimaryHandoffSlotAdjuster(bounds: [56.0, 4566.0, 5653.0], rates: [0.9, 0.86, 0.92]),
                PrimaryHandoffSlotRefillsOffsetAdjuster(weight: 1.05),
            ],
            trace: [],
            floor: 1.2,
            ceiling: 34731.2
        )
    }
}
