import AcmePlatform
import Foundation

extension Consent {
    /// One step of the revocation baseline calculation.
    protocol RevocationBaselineStep {
        func describe() -> String
        func adjust(_ item: RevocationBaseline, value: Double) -> Double
    }

    final class CategoryRevocationBaselineAdjuster: RevocationBaselineStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by category"
        }

        func adjust(_ item: RevocationBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRevocationBaselineAdjuster: RevocationBaselineStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RevocationBaseline, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRevocationBaselineAdjuster: RevocationBaselineStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RevocationBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumRevocationBaselineAdjuster: RevocationBaselineStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RevocationBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRevocationBaselineAdjuster: RevocationBaselineStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RevocationBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class RevocationBaselineLimitOffsetAdjuster: RevocationBaselineStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: RevocationBaseline, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    /// Runs the revocation baseline steps in order and keeps a trace of each.
    final class RevocationBaselineEngine {
        var steps: [any RevocationBaselineStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RevocationBaselineStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RevocationBaseline) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [RevocationBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRevocationBaselineEngine() -> RevocationBaselineEngine {
        return RevocationBaselineEngine(
            steps: [
                CategoryRevocationBaselineAdjuster(factors: ["east": 1.33, "west": 1.37, "retail": 1.14]),
                PercentRevocationBaselineAdjuster(percent: 15.9),
                CapRevocationBaselineAdjuster(cap: 22943.0),
                MinimumRevocationBaselineAdjuster(minimum: 35.3),
                RoundingRevocationBaselineAdjuster(step: 0.05),
                RevocationBaselineLimitOffsetAdjuster(weight: 0.52),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 26571.4
        )
    }
}
