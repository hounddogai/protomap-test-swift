import AcmePlatform
import Foundation

extension Labs {
    /// One step of the tiered result policy calculation.
    protocol TieredResultPolicyStep {
        func describe() -> String
        func adjust(_ item: TieredResultPolicy, value: Double) -> Double
    }

    final class PercentTieredResultPolicyAdjuster: TieredResultPolicyStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredResultPolicy, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTieredResultPolicyAdjuster: TieredResultPolicyStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredResultPolicy, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceTieredResultPolicyAdjuster: TieredResultPolicyStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: TieredResultPolicy, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the tiered result policy steps in order and keeps a trace of each.
    final class TieredResultPolicyEngine {
        var steps: [any TieredResultPolicyStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredResultPolicyStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredResultPolicy) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredResultPolicyStep = steps[index]
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

        func evaluateAll(_ items: [TieredResultPolicy]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredResultPolicyEngine() -> TieredResultPolicyEngine {
        return TieredResultPolicyEngine(
            steps: [
                PercentTieredResultPolicyAdjuster(percent: -11.5),
                TieredTieredResultPolicyAdjuster(
                    bounds: [2290.0, 2400.0, 4327.0, 7656.0],
                    rates: [1.01, 0.85, 1.01, 0.97]
                ),
                SourceTieredResultPolicyAdjuster(factors: ["east": 0.88]),
            ],
            trace: [],
            floor: 4.6,
            ceiling: 3759.8
        )
    }
}
