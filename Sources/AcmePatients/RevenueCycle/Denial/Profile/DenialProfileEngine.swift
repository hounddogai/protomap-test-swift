import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial profile calculation.
    protocol DenialProfileFactor {
        func describe() -> String
        func adjust(_ item: DenialProfile, value: Double) -> Double
    }

    final class MinimumDenialProfileAdjuster: DenialProfileFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialProfile, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapDenialProfileAdjuster: DenialProfileFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: DenialProfile, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelDenialProfileAdjuster: DenialProfileFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: DenialProfile, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingDenialProfileAdjuster: DenialProfileFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: DenialProfile, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class DenialProfileSequenceOffsetAdjuster: DenialProfileFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus sequence times \(weight)"
        }

        func adjust(_ item: DenialProfile, value: Double) -> Double {
            return value + Double(item.sequence) * weight
        }
    }

    /// Runs the denial profile steps in order and keeps a trace of each.
    final class DenialProfileEngine {
        var steps: [any DenialProfileFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialProfileFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialProfile) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any DenialProfileFactor = steps[index]
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

        func evaluateAll(_ items: [DenialProfile]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialProfileEngine() -> DenialProfileEngine {
        return DenialProfileEngine(
            steps: [
                MinimumDenialProfileAdjuster(minimum: 31.9),
                CapDenialProfileAdjuster(cap: 28172.0),
                LabelDenialProfileAdjuster(factors: ["north": 1.25]),
                RoundingDenialProfileAdjuster(step: 1.0),
                DenialProfileSequenceOffsetAdjuster(weight: 0.58),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 70257.4
        )
    }
}
