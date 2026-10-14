import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist rule calculation.
    protocol WorklistRuleAdjuster {
        func describe() -> String
        func adjust(_ item: WorklistRule, value: Double) -> Double
    }

    final class PercentWorklistRuleAdjuster: WorklistRuleAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistRule, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameWorklistRuleAdjuster: WorklistRuleAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: WorklistRule, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapWorklistRuleAdjuster: WorklistRuleAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistRule, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class WorklistRuleBatchSizeOffsetAdjuster: WorklistRuleAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: WorklistRule, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    /// Runs the worklist rule steps in order and keeps a trace of each.
    final class WorklistRuleEngine {
        var steps: [any WorklistRuleAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistRuleAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WorklistRule) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [WorklistRule]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWorklistRuleEngine() -> WorklistRuleEngine {
        return WorklistRuleEngine(
            steps: [
                PercentWorklistRuleAdjuster(percent: 21.4),
                NameWorklistRuleAdjuster(factors: ["north": 1.37, "south": 1.06, "west": 1.36]),
                CapWorklistRuleAdjuster(cap: 11772.0),
                WorklistRuleBatchSizeOffsetAdjuster(weight: 1.55),
            ],
            trace: [],
            floor: 2.6,
            ceiling: 71366.0
        )
    }
}
