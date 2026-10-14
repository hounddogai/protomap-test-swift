import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the lenient study target calculation.
    protocol LenientStudyTargetAdjuster {
        func describe() -> String
        func adjust(_ item: LenientStudyTarget, value: Double) -> Double
    }

    final class CapLenientStudyTargetAdjuster: LenientStudyTargetAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientStudyTarget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class NameLenientStudyTargetAdjuster: LenientStudyTargetAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: LenientStudyTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumLenientStudyTargetAdjuster: LenientStudyTargetAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientStudyTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingLenientStudyTargetAdjuster: LenientStudyTargetAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientStudyTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentLenientStudyTargetAdjuster: LenientStudyTargetAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientStudyTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LenientStudyTargetRateOffsetAdjuster: LenientStudyTargetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus rate times \(weight)"
        }

        func adjust(_ item: LenientStudyTarget, value: Double) -> Double {
            return value + item.rate * weight
        }
    }

    /// Runs the lenient study target steps in order and keeps a trace of each.
    final class LenientStudyTargetEngine {
        var steps: [any LenientStudyTargetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientStudyTargetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: LenientStudyTarget) -> Double {
            var current = item.effectiveValue()
            trace = []
            for index in 0..<steps.count {
                let step: any LenientStudyTargetAdjuster = steps[index]
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

        func evaluateAll(_ items: [LenientStudyTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultLenientStudyTargetEngine() -> LenientStudyTargetEngine {
        return LenientStudyTargetEngine(
            steps: [
                CapLenientStudyTargetAdjuster(cap: 22514.0),
                NameLenientStudyTargetAdjuster(factors: ["online": 1.17]),
                MinimumLenientStudyTargetAdjuster(minimum: 49.0),
                RoundingLenientStudyTargetAdjuster(step: 5.0),
                PercentLenientStudyTargetAdjuster(percent: 7.5),
                LenientStudyTargetRateOffsetAdjuster(weight: 1.82),
            ],
            trace: [],
            floor: 4.4,
            ceiling: 75533.8
        )
    }
}
