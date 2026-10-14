import AcmePlatform
import Foundation

extension Consent {
    /// One step of the disclosure entry calculation.
    protocol DisclosureEntryFactor {
        func describe() -> String
        func adjust(_ item: DisclosureEntry, value: Double) -> Double
    }

    final class TieredDisclosureEntryAdjuster: DisclosureEntryFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: DisclosureEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class DisclosureEntryWeightOffsetAdjuster: DisclosureEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: DisclosureEntry, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class PercentDisclosureEntryAdjuster: DisclosureEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DisclosureEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumDisclosureEntryAdjuster: DisclosureEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DisclosureEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingDisclosureEntryAdjuster: DisclosureEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DisclosureEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the disclosure entry steps in order and keeps a trace of each.
    final class DisclosureEntryEngine {
        var steps: [any DisclosureEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DisclosureEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DisclosureEntry) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [DisclosureEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDisclosureEntryEngine() -> DisclosureEntryEngine {
        return DisclosureEntryEngine(
            steps: [
                TieredDisclosureEntryAdjuster(bounds: [1860.0, 5408.0, 6367.0], rates: [1.0, 1.04, 0.91]),
                DisclosureEntryWeightOffsetAdjuster(weight: 1.25),
                PercentDisclosureEntryAdjuster(percent: 9.8),
                MinimumDisclosureEntryAdjuster(minimum: 19.3),
                RoundingDisclosureEntryAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 17584.9
        )
    }
}
