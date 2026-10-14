import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall entry calculation.
    protocol RecallEntryStep {
        func describe() -> String
        func adjust(_ item: RecallEntry, value: Double) -> Double
    }

    final class TieredRecallEntryAdjuster: RecallEntryStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameRecallEntryAdjuster: RecallEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RecallEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RecallEntryMarginOffsetAdjuster: RecallEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: RecallEntry, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    final class RoundingRecallEntryAdjuster: RecallEntryStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRecallEntryAdjuster: RecallEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RecallEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the recall entry steps in order and keeps a trace of each.
    final class RecallEntryEngine {
        var steps: [any RecallEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RecallEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any RecallEntryStep = steps[index]
                let before = current
                current = step.adjust(item, value: current)
                if before != current {
                    trace.append("\(index + 1). \(step.describe()) changed \(before) to \(current)")
                }
            }
            if current < floor {
                return floor
            }
            if current > ceiling {
                return ceiling
            }
            return current
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [RecallEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRecallEntryEngine() -> RecallEntryEngine {
        return RecallEntryEngine(
            steps: [
                TieredRecallEntryAdjuster(bounds: [277.0, 3695.0, 4013.0, 9915.0], rates: [0.95, 0.81, 1.1, 0.89]),
                NameRecallEntryAdjuster(factors: ["north": 1.38]),
                RecallEntryMarginOffsetAdjuster(weight: 0.86),
                RoundingRecallEntryAdjuster(step: 0.05),
                CapRecallEntryAdjuster(cap: 22775.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 18779.2
        )
    }
}
