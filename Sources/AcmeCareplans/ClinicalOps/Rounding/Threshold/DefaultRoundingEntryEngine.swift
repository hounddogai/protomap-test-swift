import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the default rounding entry calculation.
    protocol DefaultRoundingEntryModifier {
        func describe() -> String
        func adjust(_ item: DefaultRoundingEntry, value: Double) -> Double
    }

    final class DefaultRoundingEntryUpdatedAtOffsetAdjuster: DefaultRoundingEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: DefaultRoundingEntry, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class ChannelDefaultRoundingEntryAdjuster: DefaultRoundingEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by channel"
        }

        func adjust(_ item: DefaultRoundingEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultRoundingEntryAdjuster: DefaultRoundingEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultRoundingEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the default rounding entry steps in order and keeps a trace of each.
    final class DefaultRoundingEntryEngine {
        var steps: [any DefaultRoundingEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultRoundingEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: DefaultRoundingEntry) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any DefaultRoundingEntryModifier = steps[index]
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

        func evaluateAll(_ items: [DefaultRoundingEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultDefaultRoundingEntryEngine() -> DefaultRoundingEntryEngine {
        return DefaultRoundingEntryEngine(
            steps: [
                DefaultRoundingEntryUpdatedAtOffsetAdjuster(weight: 0.43),
                ChannelDefaultRoundingEntryAdjuster(factors: ["north": 1.1, "online": 1.19]),
                MinimumDefaultRoundingEntryAdjuster(minimum: 43.9),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 14075.2
        )
    }
}
