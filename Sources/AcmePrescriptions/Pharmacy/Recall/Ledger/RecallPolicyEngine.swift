import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the recall policy calculation.
    protocol RecallPolicyStep {
        func describe() -> String
        func adjust(_ item: RecallPolicy, value: Double) -> Double
    }

    final class MinimumRecallPolicyAdjuster: RecallPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RecallPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRecallPolicyAdjuster: RecallPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RecallPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredRecallPolicyAdjuster: RecallPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RecallPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class TitleRecallPolicyAdjuster: RecallPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: RecallPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentRecallPolicyAdjuster: RecallPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RecallPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RecallPolicyThresholdOffsetAdjuster: RecallPolicyStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: RecallPolicy, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the recall policy steps in order and keeps a trace of each.
    final class RecallPolicyEngine {
        var steps: [any RecallPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RecallPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: RecallPolicy) -> Double {
            var current = item.projectedTotal()
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

        func evaluateAll(_ items: [RecallPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultRecallPolicyEngine() -> RecallPolicyEngine {
        return RecallPolicyEngine(
            steps: [
                MinimumRecallPolicyAdjuster(minimum: 37.6),
                RoundingRecallPolicyAdjuster(step: 0.05),
                TieredRecallPolicyAdjuster(bounds: [612.0, 4982.0, 7287.0], rates: [1.1, 1.18, 1.01]),
                TitleRecallPolicyAdjuster(factors: ["retail": 0.75, "online": 1.1]),
                PercentRecallPolicyAdjuster(percent: -22.2),
                RecallPolicyThresholdOffsetAdjuster(weight: 0.44),
            ],
            trace: [],
            floor: 4.5,
            ceiling: 24224.6
        )
    }
}
