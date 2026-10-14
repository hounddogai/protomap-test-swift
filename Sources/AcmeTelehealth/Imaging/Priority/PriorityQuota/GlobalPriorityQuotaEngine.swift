import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the global priority quota calculation.
    protocol GlobalPriorityQuotaModifier {
        func describe() -> String
        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double
    }

    final class TieredGlobalPriorityQuotaAdjuster: GlobalPriorityQuotaModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapGlobalPriorityQuotaAdjuster: GlobalPriorityQuotaModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class GlobalPriorityQuotaUpdatedAtOffsetAdjuster: GlobalPriorityQuotaModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus updated at times \(weight)"
        }

        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double {
            return value + Double(item.updatedAt) * weight
        }
    }

    final class SegmentGlobalPriorityQuotaAdjuster: GlobalPriorityQuotaModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class PercentGlobalPriorityQuotaAdjuster: GlobalPriorityQuotaModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingGlobalPriorityQuotaAdjuster: GlobalPriorityQuotaModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: GlobalPriorityQuota, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the global priority quota steps in order and keeps a trace of each.
    final class GlobalPriorityQuotaEngine {
        var steps: [any GlobalPriorityQuotaModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalPriorityQuotaModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: GlobalPriorityQuota) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any GlobalPriorityQuotaModifier = steps[index]
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

        func evaluateAll(_ items: [GlobalPriorityQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultGlobalPriorityQuotaEngine() -> GlobalPriorityQuotaEngine {
        return GlobalPriorityQuotaEngine(
            steps: [
                TieredGlobalPriorityQuotaAdjuster(bounds: [1196.0, 8020.0], rates: [1.06, 1.04]),
                CapGlobalPriorityQuotaAdjuster(cap: 40866.0),
                GlobalPriorityQuotaUpdatedAtOffsetAdjuster(weight: 1.1),
                SegmentGlobalPriorityQuotaAdjuster(factors: ["online": 1.01, "east": 1.1, "central": 1.37]),
                PercentGlobalPriorityQuotaAdjuster(percent: 20.5),
                RoundingGlobalPriorityQuotaAdjuster(step: 1.0),
            ],
            trace: [],
            floor: 1.0,
            ceiling: 77177.5
        )
    }
}
