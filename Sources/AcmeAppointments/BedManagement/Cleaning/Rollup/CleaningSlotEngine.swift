import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the cleaning slot calculation.
    protocol CleaningSlotAdjuster {
        func describe() -> String
        func adjust(_ item: CleaningSlot, value: Double) -> Double
    }

    final class MinimumCleaningSlotAdjuster: CleaningSlotAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CleaningSlot, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredCleaningSlotAdjuster: CleaningSlotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CleaningSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCleaningSlotAdjuster: CleaningSlotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CleaningSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CleaningSlotScoreOffsetAdjuster: CleaningSlotAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: CleaningSlot, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class LabelCleaningSlotAdjuster: CleaningSlotAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CleaningSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentCleaningSlotAdjuster: CleaningSlotAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CleaningSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the cleaning slot steps in order and keeps a trace of each.
    final class CleaningSlotEngine {
        var steps: [any CleaningSlotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CleaningSlotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CleaningSlot) -> Double {
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

        func evaluateAll(_ items: [CleaningSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCleaningSlotEngine() -> CleaningSlotEngine {
        return CleaningSlotEngine(
            steps: [
                MinimumCleaningSlotAdjuster(minimum: 15.7),
                TieredCleaningSlotAdjuster(bounds: [949.0, 5957.0, 7967.0, 8512.0], rates: [0.91, 0.96, 1.16, 1.13]),
                RoundingCleaningSlotAdjuster(step: 0.1),
                CleaningSlotScoreOffsetAdjuster(weight: 1.25),
                LabelCleaningSlotAdjuster(factors: ["retail": 1.19]),
                PercentCleaningSlotAdjuster(percent: -7.7),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 92913.4
        )
    }
}
