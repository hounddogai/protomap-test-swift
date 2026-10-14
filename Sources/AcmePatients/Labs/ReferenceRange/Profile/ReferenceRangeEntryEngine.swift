import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range entry calculation.
    protocol ReferenceRangeEntryFactor {
        func describe() -> String
        func adjust(_ item: ReferenceRangeEntry, value: Double) -> Double
    }

    final class RoundingReferenceRangeEntryAdjuster: ReferenceRangeEntryFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReferenceRangeEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumReferenceRangeEntryAdjuster: ReferenceRangeEntryFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ReferenceRangeEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapReferenceRangeEntryAdjuster: ReferenceRangeEntryFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ReferenceRangeEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentReferenceRangeEntryAdjuster: ReferenceRangeEntryFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReferenceRangeEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeEntryExpiresAtOffsetAdjuster: ReferenceRangeEntryFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus expires at times \(weight)"
        }

        func adjust(_ item: ReferenceRangeEntry, value: Double) -> Double {
            return value + Double(item.expiresAt) * weight
        }
    }

    /// Runs the reference range entry steps in order and keeps a trace of each.
    final class ReferenceRangeEntryEngine {
        var steps: [any ReferenceRangeEntryFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeEntryFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ReferenceRangeEntry) -> Double {
            var current = item.weightedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any ReferenceRangeEntryFactor = steps[index]
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

        func evaluateAll(_ items: [ReferenceRangeEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeEntryEngine() -> ReferenceRangeEntryEngine {
        return ReferenceRangeEntryEngine(
            steps: [
                RoundingReferenceRangeEntryAdjuster(step: 0.5),
                MinimumReferenceRangeEntryAdjuster(minimum: 13.6),
                CapReferenceRangeEntryAdjuster(cap: 23518.0),
                PercentReferenceRangeEntryAdjuster(percent: -4.4),
                ReferenceRangeEntryExpiresAtOffsetAdjuster(weight: 0.61),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 36006.5
        )
    }
}
