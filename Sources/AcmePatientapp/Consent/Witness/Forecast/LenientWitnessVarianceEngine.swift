import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient witness variance calculation.
    protocol LenientWitnessVarianceModifier {
        func describe() -> String
        func adjust(_ item: LenientWitnessVariance, value: Double) -> Double
    }

    final class PercentLenientWitnessVarianceAdjuster: LenientWitnessVarianceModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientWitnessVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientWitnessVarianceMinimumOffsetAdjuster: LenientWitnessVarianceModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus minimum times \(weight)"
        }

        func adjust(_ item: LenientWitnessVariance, value: Double) -> Double {
            return value + item.minimum * weight
        }
    }

    final class CapLenientWitnessVarianceAdjuster: LenientWitnessVarianceModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientWitnessVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient witness variance steps in order and keeps a trace of each.
    final class LenientWitnessVarianceEngine {
        var steps: [any LenientWitnessVarianceModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientWitnessVarianceModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientWitnessVariance) -> Double {
            var current = item.projectedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientWitnessVarianceModifier = steps[index]
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

        func evaluateAll(_ items: [LenientWitnessVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientWitnessVarianceEngine() -> LenientWitnessVarianceEngine {
        return LenientWitnessVarianceEngine(
            steps: [
                PercentLenientWitnessVarianceAdjuster(percent: -0.4),
                LenientWitnessVarianceMinimumOffsetAdjuster(weight: 0.39),
                CapLenientWitnessVarianceAdjuster(cap: 11639.0),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 50961.9
        )
    }
}
