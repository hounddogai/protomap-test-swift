import AcmePlatform
import Foundation

extension Consent {
    /// One step of the lenient proxy budget calculation.
    protocol LenientProxyBudgetStep {
        func describe() -> String
        func adjust(_ item: LenientProxyBudget, value: Double) -> Double
    }

    final class MinimumLenientProxyBudgetAdjuster: LenientProxyBudgetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LenientProxyBudget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentLenientProxyBudgetAdjuster: LenientProxyBudgetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: LenientProxyBudget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingLenientProxyBudgetAdjuster: LenientProxyBudgetStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: LenientProxyBudget, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapLenientProxyBudgetAdjuster: LenientProxyBudgetStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: LenientProxyBudget, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the lenient proxy budget steps in order and keeps a trace of each.
    final class LenientProxyBudgetEngine {
        var steps: [any LenientProxyBudgetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LenientProxyBudgetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: LenientProxyBudget) -> Double {
            var current = item.projectedVolume()
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

        func evaluateAll(_ items: [LenientProxyBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultLenientProxyBudgetEngine() -> LenientProxyBudgetEngine {
        return LenientProxyBudgetEngine(
            steps: [
                MinimumLenientProxyBudgetAdjuster(minimum: 33.1),
                PercentLenientProxyBudgetAdjuster(percent: -15.1),
                RoundingLenientProxyBudgetAdjuster(step: 0.1),
                CapLenientProxyBudgetAdjuster(cap: 38712.0),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 23999.0
        )
    }
}
