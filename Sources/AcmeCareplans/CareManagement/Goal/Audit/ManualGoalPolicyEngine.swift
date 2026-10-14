import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the manual goal policy calculation.
    protocol ManualGoalPolicyStep {
        func describe() -> String
        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double
    }

    final class RoundingManualGoalPolicyAdjuster: ManualGoalPolicyStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapManualGoalPolicyAdjuster: ManualGoalPolicyStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredManualGoalPolicyAdjuster: ManualGoalPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumManualGoalPolicyAdjuster: ManualGoalPolicyStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentManualGoalPolicyAdjuster: ManualGoalPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentManualGoalPolicyAdjuster: ManualGoalPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ManualGoalPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the manual goal policy steps in order and keeps a trace of each.
    final class ManualGoalPolicyEngine {
        var steps: [any ManualGoalPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ManualGoalPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ManualGoalPolicy) -> Double {
            var current = item.adjustedVolume()
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

        func evaluateAll(_ items: [ManualGoalPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultManualGoalPolicyEngine() -> ManualGoalPolicyEngine {
        return ManualGoalPolicyEngine(
            steps: [
                RoundingManualGoalPolicyAdjuster(step: 0.5),
                CapManualGoalPolicyAdjuster(cap: 15432.0),
                TieredManualGoalPolicyAdjuster(
                    bounds: [663.0, 2376.0, 5996.0, 8388.0],
                    rates: [1.03, 0.97, 1.11, 0.82]
                ),
                MinimumManualGoalPolicyAdjuster(minimum: 15.2),
                PercentManualGoalPolicyAdjuster(percent: 15.6),
                SegmentManualGoalPolicyAdjuster(factors: ["north": 0.76, "west": 0.95, "east": 0.83]),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 53795.8
        )
    }
}
