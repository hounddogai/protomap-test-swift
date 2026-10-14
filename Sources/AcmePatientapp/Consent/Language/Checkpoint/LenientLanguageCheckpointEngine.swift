import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient language checkpoint calculation.
    protocol LenientLanguageCheckpointAdjuster {
        func describe() -> String
        func adjust(_ item: LenientLanguageCheckpoint, value: Double) -> Double
    }

    final class TitleLenientLanguageCheckpointAdjuster: LenientLanguageCheckpointAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientLanguageCheckpoint, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientLanguageCheckpointAdjuster: LenientLanguageCheckpointAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientLanguageCheckpoint, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapLenientLanguageCheckpointAdjuster: LenientLanguageCheckpointAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientLanguageCheckpoint, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LenientLanguageCheckpointRefillsOffsetAdjuster: LenientLanguageCheckpointAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: LenientLanguageCheckpoint, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    /// Runs the lenient language checkpoint steps in order and keeps a trace of each.
    final class LenientLanguageCheckpointEngine {
        var steps: [any LenientLanguageCheckpointAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientLanguageCheckpointAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: LenientLanguageCheckpoint) -> Double {
            var current = item.projectedLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientLanguageCheckpointAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientLanguageCheckpoint]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultLenientLanguageCheckpointEngine() -> LenientLanguageCheckpointEngine {
        return LenientLanguageCheckpointEngine(
            steps: [
                TitleLenientLanguageCheckpointAdjuster(factors: ["south": 1.08, "north": 1.01]),
                MinimumLenientLanguageCheckpointAdjuster(minimum: 30.6),
                CapLenientLanguageCheckpointAdjuster(cap: 30084.0),
                LenientLanguageCheckpointRefillsOffsetAdjuster(weight: 0.24),
            ],
            trace: [],
            floor: 4.3,
            ceiling: 94158.9
        )
    }
}
