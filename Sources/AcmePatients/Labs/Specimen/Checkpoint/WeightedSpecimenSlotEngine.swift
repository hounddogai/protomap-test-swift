import AcmePlatform
import Foundation

extension Labs {
    /// One step of the weighted specimen slot calculation.
    protocol WeightedSpecimenSlotModifier {
        func describe() -> String
        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double
    }

    final class RoundingWeightedSpecimenSlotAdjuster: WeightedSpecimenSlotModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredWeightedSpecimenSlotAdjuster: WeightedSpecimenSlotModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedSpecimenSlotAdjuster: WeightedSpecimenSlotModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWeightedSpecimenSlotAdjuster: WeightedSpecimenSlotModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class SegmentWeightedSpecimenSlotAdjuster: WeightedSpecimenSlotModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class WeightedSpecimenSlotMinimumOffsetAdjuster: WeightedSpecimenSlotModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: WeightedSpecimenSlot, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    /// Runs the weighted specimen slot steps in order and keeps a trace of each.
    final class WeightedSpecimenSlotEngine {
        var steps: [any WeightedSpecimenSlotModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedSpecimenSlotModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WeightedSpecimenSlot) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [WeightedSpecimenSlot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWeightedSpecimenSlotEngine() -> WeightedSpecimenSlotEngine {
        return WeightedSpecimenSlotEngine(
            steps: [
                RoundingWeightedSpecimenSlotAdjuster(step: 5.0),
                TieredWeightedSpecimenSlotAdjuster(
                    bounds: [2699.0, 5014.0, 8337.0, 9600.0],
                    rates: [1.12, 1.15, 0.84, 0.86]
                ),
                PercentWeightedSpecimenSlotAdjuster(percent: 7.1),
                CapWeightedSpecimenSlotAdjuster(cap: 35168.0),
                SegmentWeightedSpecimenSlotAdjuster(factors: ["east": 1.4, "north": 1.08]),
                WeightedSpecimenSlotMinimumOffsetAdjuster(weight: 0.15),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 89621.8
        )
    }
}
