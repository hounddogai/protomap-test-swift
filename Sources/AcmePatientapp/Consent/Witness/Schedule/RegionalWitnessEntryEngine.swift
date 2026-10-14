import AcmePlatform
import Foundation

extension Consent {
    /// One step of the regional witness entry calculation.
    protocol RegionalWitnessEntryStep {
        func describe() -> String
        func adjust(_ item: RegionalWitnessEntry, value: Double) -> Double
    }

    final class MinimumRegionalWitnessEntryAdjuster: RegionalWitnessEntryStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalWitnessEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredRegionalWitnessEntryAdjuster: RegionalWitnessEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RegionalWitnessEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RegionalWitnessEntryMaximumOffsetAdjuster: RegionalWitnessEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus maximum times \(weight)"
        }

        func adjust(_ item: RegionalWitnessEntry, value: Double) -> Double {
            return value + item.maximum * weight
        }
    }

    final class CategoryRegionalWitnessEntryAdjuster: RegionalWitnessEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RegionalWitnessEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the regional witness entry steps in order and keeps a trace of each.
    final class RegionalWitnessEntryEngine {
        var steps: [any RegionalWitnessEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalWitnessEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RegionalWitnessEntry) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [RegionalWitnessEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRegionalWitnessEntryEngine() -> RegionalWitnessEntryEngine {
        return RegionalWitnessEntryEngine(
            steps: [
                MinimumRegionalWitnessEntryAdjuster(minimum: 45.0),
                TieredRegionalWitnessEntryAdjuster(bounds: [2605.0, 9044.0], rates: [0.98, 1.12]),
                RegionalWitnessEntryMaximumOffsetAdjuster(weight: 1.46),
                CategoryRegionalWitnessEntryAdjuster(factors: ["north": 0.79, "west": 0.86]),
            ],
            trace: [],
            floor: 4.2,
            ceiling: 43926.8
        )
    }
}
