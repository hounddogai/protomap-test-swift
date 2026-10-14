import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim target calculation.
    protocol ClaimTargetModifier {
        func describe() -> String
        func adjust(_ item: ClaimTarget, value: Double) -> Double
    }

    final class LocaleClaimTargetAdjuster: ClaimTargetModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ClaimTarget, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentClaimTargetAdjuster: ClaimTargetModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingClaimTargetAdjuster: ClaimTargetModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimTarget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the claim target steps in order and keeps a trace of each.
    final class ClaimTargetEngine {
        var steps: [any ClaimTargetModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimTargetModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ClaimTarget) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [ClaimTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultClaimTargetEngine() -> ClaimTargetEngine {
        return ClaimTargetEngine(
            steps: [
                LocaleClaimTargetAdjuster(factors: ["online": 0.88]),
                PercentClaimTargetAdjuster(percent: -14.2),
                RoundingClaimTargetAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 98316.0
        )
    }
}
