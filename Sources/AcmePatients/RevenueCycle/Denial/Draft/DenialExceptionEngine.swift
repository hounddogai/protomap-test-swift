import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the denial exception calculation.
    protocol DenialExceptionModifier {
        func describe() -> String
        func adjust(_ item: DenialException, value: Double) -> Double
    }

    final class SegmentDenialExceptionAdjuster: DenialExceptionModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: DenialException, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDenialExceptionAdjuster: DenialExceptionModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DenialException, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentDenialExceptionAdjuster: DenialExceptionModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: DenialException, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the denial exception steps in order and keeps a trace of each.
    final class DenialExceptionEngine {
        var steps: [any DenialExceptionModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DenialExceptionModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: DenialException) -> Double {
            var current = item.weightedLoad()
            trace = []
            for step in steps {
                let next = step.adjust(item, value: current)
                trace.append("\(step.describe()): \((current * 100).rounded() / 100) -> \((next * 100).rounded() / 100)")
                current = next
            }
            return Kit.Numbers.clampFloat(current, low: floor, high: ceiling)
        }

        func explain() -> String {
            return trace.joined(separator: "\n")
        }

        func evaluateAll(_ items: [DenialException]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultDenialExceptionEngine() -> DenialExceptionEngine {
        return DenialExceptionEngine(
            steps: [
                SegmentDenialExceptionAdjuster(factors: ["retail": 1.06]),
                MinimumDenialExceptionAdjuster(minimum: 28.5),
                PercentDenialExceptionAdjuster(percent: -10.2),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 83122.9
        )
    }
}
