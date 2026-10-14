import AcmePlatform
import Foundation

extension Labs {
    /// One step of the manual courier entry calculation.
    protocol ManualCourierEntryModifier {
        func describe() -> String
        func adjust(_ item: ManualCourierEntry, value: Double) -> Double
    }

    final class RoundingManualCourierEntryAdjuster: ManualCourierEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualCourierEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class NameManualCourierEntryAdjuster: ManualCourierEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ManualCourierEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ManualCourierEntryScoreOffsetAdjuster: ManualCourierEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: ManualCourierEntry, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class TieredManualCourierEntryAdjuster: ManualCourierEntryModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualCourierEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapManualCourierEntryAdjuster: ManualCourierEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualCourierEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the manual courier entry steps in order and keeps a trace of each.
    final class ManualCourierEntryEngine {
        var steps: [any ManualCourierEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualCourierEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualCourierEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ManualCourierEntryModifier = steps[index]
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

        func evaluateAll(_ items: [ManualCourierEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualCourierEntryEngine() -> ManualCourierEntryEngine {
        return ManualCourierEntryEngine(
            steps: [
                RoundingManualCourierEntryAdjuster(step: 5.0),
                NameManualCourierEntryAdjuster(factors: ["south": 1.34]),
                ManualCourierEntryScoreOffsetAdjuster(weight: 1.17),
                TieredManualCourierEntryAdjuster(bounds: [1237.0, 7459.0], rates: [0.99, 0.92]),
                CapManualCourierEntryAdjuster(cap: 23413.0),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 24728.2
        )
    }
}
