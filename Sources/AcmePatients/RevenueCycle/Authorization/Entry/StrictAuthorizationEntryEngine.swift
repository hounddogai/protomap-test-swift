import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the strict authorization entry calculation.
    protocol StrictAuthorizationEntryModifier {
        func describe() -> String
        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double
    }

    final class MinimumStrictAuthorizationEntryAdjuster: StrictAuthorizationEntryModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingStrictAuthorizationEntryAdjuster: StrictAuthorizationEntryModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelStrictAuthorizationEntryAdjuster: StrictAuthorizationEntryModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StrictAuthorizationEntryCreatedAtOffsetAdjuster: StrictAuthorizationEntryModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentStrictAuthorizationEntryAdjuster: StrictAuthorizationEntryModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapStrictAuthorizationEntryAdjuster: StrictAuthorizationEntryModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictAuthorizationEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the strict authorization entry steps in order and keeps a trace of each.
    final class StrictAuthorizationEntryEngine {
        var steps: [any StrictAuthorizationEntryModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictAuthorizationEntryModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictAuthorizationEntry) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictAuthorizationEntryModifier = steps[index]
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

        func evaluateAll(_ items: [StrictAuthorizationEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictAuthorizationEntryEngine() -> StrictAuthorizationEntryEngine {
        return StrictAuthorizationEntryEngine(
            steps: [
                MinimumStrictAuthorizationEntryAdjuster(minimum: 14.1),
                RoundingStrictAuthorizationEntryAdjuster(step: 0.5),
                LabelStrictAuthorizationEntryAdjuster(factors: ["central": 0.82, "north": 1.16, "east": 1.11]),
                StrictAuthorizationEntryCreatedAtOffsetAdjuster(weight: 1.38),
                PercentStrictAuthorizationEntryAdjuster(percent: 6.1),
                CapStrictAuthorizationEntryAdjuster(cap: 6909.0),
            ],
            trace: [],
            floor: 0.6,
            ceiling: 51199.5
        )
    }
}
