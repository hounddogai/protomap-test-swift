import AcmePlatform
import Foundation

extension Consent {
    /// One step of the weighted witness entry calculation.
    protocol WeightedWitnessEntryModifier {
        func describe() -> String
        func adjust(_ item: WeightedWitnessEntry, value: Double) -> Double
    }

    final class RoundingWeightedWitnessEntryAdjuster: WeightedWitnessEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedWitnessEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapWeightedWitnessEntryAdjuster: WeightedWitnessEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WeightedWitnessEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredWeightedWitnessEntryAdjuster: WeightedWitnessEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: WeightedWitnessEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentWeightedWitnessEntryAdjuster: WeightedWitnessEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedWitnessEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted witness entry steps in order and keeps a trace of each.
    final class WeightedWitnessEntryEngine {
        var steps: [any WeightedWitnessEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedWitnessEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: WeightedWitnessEntry) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [WeightedWitnessEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultWeightedWitnessEntryEngine() -> WeightedWitnessEntryEngine {
        return WeightedWitnessEntryEngine(
            steps: [
                RoundingWeightedWitnessEntryAdjuster(step: 0.05),
                CapWeightedWitnessEntryAdjuster(cap: 16182.0),
                TieredWeightedWitnessEntryAdjuster(
                    bounds: [530.0, 4073.0, 6085.0, 9903.0],
                    rates: [1.17, 1.01, 1.15, 0.99]
                ),
                PercentWeightedWitnessEntryAdjuster(percent: 10.2),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 13761.2
        )
    }
}
