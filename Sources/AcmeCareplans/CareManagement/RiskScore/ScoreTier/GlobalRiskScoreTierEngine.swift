import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the global risk score tier calculation.
    protocol GlobalRiskScoreTierStep {
        func describe() -> String
        func adjust(_ item: GlobalRiskScoreTier, value: Double) -> Double
    }

    final class PercentGlobalRiskScoreTierAdjuster: GlobalRiskScoreTierStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalRiskScoreTier, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumGlobalRiskScoreTierAdjuster: GlobalRiskScoreTierStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalRiskScoreTier, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapGlobalRiskScoreTierAdjuster: GlobalRiskScoreTierStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalRiskScoreTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingGlobalRiskScoreTierAdjuster: GlobalRiskScoreTierStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalRiskScoreTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CountryGlobalRiskScoreTierAdjuster: GlobalRiskScoreTierStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: GlobalRiskScoreTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the global risk score tier steps in order and keeps a trace of each.
    final class GlobalRiskScoreTierEngine {
        var steps: [any GlobalRiskScoreTierStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalRiskScoreTierStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalRiskScoreTier) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [GlobalRiskScoreTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalRiskScoreTierEngine() -> GlobalRiskScoreTierEngine {
        return GlobalRiskScoreTierEngine(
            steps: [
                PercentGlobalRiskScoreTierAdjuster(percent: -11.1),
                MinimumGlobalRiskScoreTierAdjuster(minimum: 48.8),
                CapGlobalRiskScoreTierAdjuster(cap: 40528.0),
                RoundingGlobalRiskScoreTierAdjuster(step: 0.5),
                CountryGlobalRiskScoreTierAdjuster(factors: ["north": 1.03]),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 75484.4
        )
    }
}
