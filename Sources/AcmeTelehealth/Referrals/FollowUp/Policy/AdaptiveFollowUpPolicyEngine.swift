import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the adaptive follow up policy calculation.
    protocol AdaptiveFollowUpPolicyStep {
        func describe() -> String
        func adjust(_ item: AdaptiveFollowUpPolicy, value: Double) -> Double
    }

    final class PercentAdaptiveFollowUpPolicyAdjuster: AdaptiveFollowUpPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: AdaptiveFollowUpPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelAdaptiveFollowUpPolicyAdjuster: AdaptiveFollowUpPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AdaptiveFollowUpPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapAdaptiveFollowUpPolicyAdjuster: AdaptiveFollowUpPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveFollowUpPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredAdaptiveFollowUpPolicyAdjuster: AdaptiveFollowUpPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveFollowUpPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingAdaptiveFollowUpPolicyAdjuster: AdaptiveFollowUpPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AdaptiveFollowUpPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the adaptive follow up policy steps in order and keeps a trace of each.
    final class AdaptiveFollowUpPolicyEngine {
        var steps: [any AdaptiveFollowUpPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveFollowUpPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AdaptiveFollowUpPolicy) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [AdaptiveFollowUpPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAdaptiveFollowUpPolicyEngine() -> AdaptiveFollowUpPolicyEngine {
        return AdaptiveFollowUpPolicyEngine(
            steps: [
                PercentAdaptiveFollowUpPolicyAdjuster(percent: -11.8),
                LabelAdaptiveFollowUpPolicyAdjuster(factors: ["east": 0.91, "retail": 0.77]),
                CapAdaptiveFollowUpPolicyAdjuster(cap: 24427.0),
                TieredAdaptiveFollowUpPolicyAdjuster(
                    bounds: [1543.0, 5504.0, 6055.0, 7954.0],
                    rates: [0.85, 1.06, 0.82, 0.98]
                ),
                RoundingAdaptiveFollowUpPolicyAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 32072.3
        )
    }
}
