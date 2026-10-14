import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the lenient authorization variance calculation.
    protocol LenientAuthorizationVarianceFactor {
        func describe() -> String
        func adjust(_ item: LenientAuthorizationVariance, value: Double) -> Double
    }

    final class PercentLenientAuthorizationVarianceAdjuster: LenientAuthorizationVarianceFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientAuthorizationVariance, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapLenientAuthorizationVarianceAdjuster: LenientAuthorizationVarianceFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientAuthorizationVariance, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleLenientAuthorizationVarianceAdjuster: LenientAuthorizationVarianceFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: LenientAuthorizationVariance, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingLenientAuthorizationVarianceAdjuster: LenientAuthorizationVarianceFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientAuthorizationVariance, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LenientAuthorizationVarianceAttemptsOffsetAdjuster: LenientAuthorizationVarianceFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: LenientAuthorizationVariance, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    /// Runs the lenient authorization variance steps in order and keeps a trace of each.
    final class LenientAuthorizationVarianceEngine {
        var steps: [any LenientAuthorizationVarianceFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientAuthorizationVarianceFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientAuthorizationVariance) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientAuthorizationVarianceFactor = steps[index]
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

        func evaluateAll(_ items: [LenientAuthorizationVariance]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientAuthorizationVarianceEngine() -> LenientAuthorizationVarianceEngine {
        return LenientAuthorizationVarianceEngine(
            steps: [
                PercentLenientAuthorizationVarianceAdjuster(percent: -14.6),
                CapLenientAuthorizationVarianceAdjuster(cap: 5643.0),
                TitleLenientAuthorizationVarianceAdjuster(factors: ["retail": 1.07, "north": 1.13, "west": 0.83]),
                RoundingLenientAuthorizationVarianceAdjuster(step: 0.1),
                LenientAuthorizationVarianceAttemptsOffsetAdjuster(weight: 0.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 81166.2
        )
    }
}
