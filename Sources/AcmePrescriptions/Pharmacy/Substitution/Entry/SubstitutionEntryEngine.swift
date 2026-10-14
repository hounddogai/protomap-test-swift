import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the substitution entry calculation.
    protocol SubstitutionEntryFactor {
        func describe() -> String
        func adjust(_ item: SubstitutionEntry, value: Double) -> Double
    }

    final class SubstitutionEntryVersionOffsetAdjuster: SubstitutionEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: SubstitutionEntry, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class RoundingSubstitutionEntryAdjuster: SubstitutionEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: SubstitutionEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RegionSubstitutionEntryAdjuster: SubstitutionEntryFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: SubstitutionEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentSubstitutionEntryAdjuster: SubstitutionEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SubstitutionEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the substitution entry steps in order and keeps a trace of each.
    final class SubstitutionEntryEngine {
        var steps: [any SubstitutionEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SubstitutionEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SubstitutionEntry) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [SubstitutionEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSubstitutionEntryEngine() -> SubstitutionEntryEngine {
        return SubstitutionEntryEngine(
            steps: [
                SubstitutionEntryVersionOffsetAdjuster(weight: 0.98),
                RoundingSubstitutionEntryAdjuster(step: 5.0),
                RegionSubstitutionEntryAdjuster(factors: ["south": 0.89, "central": 1.13, "east": 0.79]),
                PercentSubstitutionEntryAdjuster(percent: 8.6),
            ],
            trace: [],
            floor: 0.7,
            ceiling: 54325.5
        )
    }
}
