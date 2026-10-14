import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled risk score group calculation.
    protocol ScheduledRiskScoreGroupStep {
        func describe() -> String
        func adjust(_ item: ScheduledRiskScoreGroup, value: Double) -> Double
    }

    final class SourceScheduledRiskScoreGroupAdjuster: ScheduledRiskScoreGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: ScheduledRiskScoreGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ScheduledRiskScoreGroupBatchSizeOffsetAdjuster: ScheduledRiskScoreGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ScheduledRiskScoreGroup, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredScheduledRiskScoreGroupAdjuster: ScheduledRiskScoreGroupStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledRiskScoreGroup, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentScheduledRiskScoreGroupAdjuster: ScheduledRiskScoreGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledRiskScoreGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapScheduledRiskScoreGroupAdjuster: ScheduledRiskScoreGroupStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledRiskScoreGroup, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled risk score group steps in order and keeps a trace of each.
    final class ScheduledRiskScoreGroupEngine {
        var steps: [any ScheduledRiskScoreGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledRiskScoreGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledRiskScoreGroup) -> Double {
            var current = item.projectedValue()
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

        func evaluateAll(_ items: [ScheduledRiskScoreGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledRiskScoreGroupEngine() -> ScheduledRiskScoreGroupEngine {
        return ScheduledRiskScoreGroupEngine(
            steps: [
                SourceScheduledRiskScoreGroupAdjuster(factors: ["retail": 0.94, "east": 1.13, "south": 1.13]),
                ScheduledRiskScoreGroupBatchSizeOffsetAdjuster(weight: 1.67),
                TieredScheduledRiskScoreGroupAdjuster(bounds: [102.0, 1807.0], rates: [1.19, 1.18]),
                PercentScheduledRiskScoreGroupAdjuster(percent: 18.4),
                CapScheduledRiskScoreGroupAdjuster(cap: 3707.0),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 66193.6
        )
    }
}
