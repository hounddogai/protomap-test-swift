import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict specimen entry calculation.
    protocol StrictSpecimenEntryStep {
        func describe() -> String
        func adjust(_ item: StrictSpecimenEntry, value: Double) -> Double
    }

    final class CapStrictSpecimenEntryAdjuster: StrictSpecimenEntryStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictSpecimenEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictSpecimenEntryBudgetOffsetAdjuster: StrictSpecimenEntryStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus budget times \(weight)"
        }

        func adjust(_ item: StrictSpecimenEntry, value: Double) -> Double {
            return value + item.budget * weight
        }
    }

    final class ChannelStrictSpecimenEntryAdjuster: StrictSpecimenEntryStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: StrictSpecimenEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the strict specimen entry steps in order and keeps a trace of each.
    final class StrictSpecimenEntryEngine {
        var steps: [any StrictSpecimenEntryStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictSpecimenEntryStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: StrictSpecimenEntry) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictSpecimenEntryStep = steps[index]
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

        func evaluateAll(_ items: [StrictSpecimenEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultStrictSpecimenEntryEngine() -> StrictSpecimenEntryEngine {
        return StrictSpecimenEntryEngine(
            steps: [
                CapStrictSpecimenEntryAdjuster(cap: 25878.0),
                StrictSpecimenEntryBudgetOffsetAdjuster(weight: 1.92),
                ChannelStrictSpecimenEntryAdjuster(factors: ["south": 1.24]),
            ],
            trace: [],
            floor: 4.8,
            ceiling: 93057.4
        )
    }
}
