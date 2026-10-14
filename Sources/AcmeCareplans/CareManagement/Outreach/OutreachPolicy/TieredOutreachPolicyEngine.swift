import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the tiered outreach policy calculation.
    protocol TieredOutreachPolicyStep {
        func describe() -> String
        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double
    }

    final class TieredOutreachPolicyThresholdOffsetAdjuster: TieredOutreachPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    final class MinimumTieredOutreachPolicyAdjuster: TieredOutreachPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapTieredOutreachPolicyAdjuster: TieredOutreachPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingTieredOutreachPolicyAdjuster: TieredOutreachPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredTieredOutreachPolicyAdjuster: TieredOutreachPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredOutreachPolicyAdjuster: TieredOutreachPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredOutreachPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the tiered outreach policy steps in order and keeps a trace of each.
    final class TieredOutreachPolicyEngine {
        var steps: [any TieredOutreachPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredOutreachPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredOutreachPolicy) -> Double {
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

        func evaluateAll(_ items: [TieredOutreachPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredOutreachPolicyEngine() -> TieredOutreachPolicyEngine {
        return TieredOutreachPolicyEngine(
            steps: [
                TieredOutreachPolicyThresholdOffsetAdjuster(weight: 1.29),
                MinimumTieredOutreachPolicyAdjuster(minimum: 21.4),
                CapTieredOutreachPolicyAdjuster(cap: 6085.0),
                RoundingTieredOutreachPolicyAdjuster(step: 0.25),
                TieredTieredOutreachPolicyAdjuster(bounds: [604.0, 3475.0, 6681.0], rates: [1.09, 0.81, 0.89]),
                PercentTieredOutreachPolicyAdjuster(percent: 1.9),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 30203.1
        )
    }
}
