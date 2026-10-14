import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language checkpoint calculation.
    protocol LanguageCheckpointFactor {
        func describe() -> String
        func adjust(_ item: LanguageCheckpoint, value: Double) -> Double
    }

    final class CapLanguageCheckpointAdjuster: LanguageCheckpointFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LanguageCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LanguageCheckpointCapacityOffsetAdjuster: LanguageCheckpointFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: LanguageCheckpoint, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class MinimumLanguageCheckpointAdjuster: LanguageCheckpointFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLanguageCheckpointAdjuster: LanguageCheckpointFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LanguageCheckpoint, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the language checkpoint steps in order and keeps a trace of each.
    final class LanguageCheckpointEngine {
        var steps: [any LanguageCheckpointFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageCheckpointFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageCheckpoint) -> Double {
            var current = item.adjustedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageCheckpointFactor = steps[index]
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

        func evaluateAll(_ items: [LanguageCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageCheckpointEngine() -> LanguageCheckpointEngine {
        return LanguageCheckpointEngine(
            steps: [
                CapLanguageCheckpointAdjuster(cap: 39387.0),
                LanguageCheckpointCapacityOffsetAdjuster(weight: 1.65),
                MinimumLanguageCheckpointAdjuster(minimum: 25.1),
                RoundingLanguageCheckpointAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 16132.6
        )
    }
}
