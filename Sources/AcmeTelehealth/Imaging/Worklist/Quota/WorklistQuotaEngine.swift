import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the worklist quota calculation.
    protocol WorklistQuotaStep {
        func describe() -> String
        func adjust(_ item: WorklistQuota, value: Double) -> Double
    }

    final class PercentWorklistQuotaAdjuster: WorklistQuotaStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WorklistQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapWorklistQuotaAdjuster: WorklistQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: WorklistQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TitleWorklistQuotaAdjuster: WorklistQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: WorklistQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumWorklistQuotaAdjuster: WorklistQuotaStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WorklistQuota, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class WorklistQuotaAmountOffsetAdjuster: WorklistQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: WorklistQuota, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    /// Runs the worklist quota steps in order and keeps a trace of each.
    final class WorklistQuotaEngine {
        var steps: [any WorklistQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WorklistQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: WorklistQuota) -> Double {
            var current = item.netTotal()
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

        func evaluateAll(_ items: [WorklistQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultWorklistQuotaEngine() -> WorklistQuotaEngine {
        return WorklistQuotaEngine(
            steps: [
                PercentWorklistQuotaAdjuster(percent: 19.9),
                CapWorklistQuotaAdjuster(cap: 20584.0),
                TitleWorklistQuotaAdjuster(factors: ["online": 1.32]),
                MinimumWorklistQuotaAdjuster(minimum: 40.9),
                WorklistQuotaAmountOffsetAdjuster(weight: 1.69),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 19599.6
        )
    }
}
