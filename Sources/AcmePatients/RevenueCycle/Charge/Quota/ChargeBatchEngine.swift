import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the charge batch calculation.
    protocol ChargeBatchStep {
        func describe() -> String
        func adjust(_ item: ChargeBatch, value: Double) -> Double
    }

    final class SegmentChargeBatchAdjuster: ChargeBatchStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ChargeBatch, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class ChargeBatchCopayOffsetAdjuster: ChargeBatchStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus copay times \(weight)"
        }

        func adjust(_ item: ChargeBatch, value: Double) -> Double {
            return value + item.copay * weight
        }
    }

    final class PercentChargeBatchAdjuster: ChargeBatchStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ChargeBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedChargeBatchAdjuster: ChargeBatchStep {
        var flags: Kit.Flags.Registry
        var flag: String
        var percent: Double

        init(flags: Kit.Flags.Registry, flag: String, percent: Double) {
            self.flags = flags
            self.flag = flag
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent) when \(flag) is on"
        }

        func adjust(_ item: ChargeBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredChargeBatchAdjuster: ChargeBatchStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ChargeBatch, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumChargeBatchAdjuster: ChargeBatchStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ChargeBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the charge batch steps in order and keeps a trace of each.
    final class ChargeBatchEngine {
        var steps: [any ChargeBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ChargeBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ChargeBatch) -> Double {
            var current = item.effectiveTotal()
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

        func evaluateAll(_ items: [ChargeBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultChargeBatchEngine(_ flags: Kit.Flags.Registry) -> ChargeBatchEngine {
        return ChargeBatchEngine(
            steps: [
                SegmentChargeBatchAdjuster(factors: ["central": 1.07]),
                ChargeBatchCopayOffsetAdjuster(weight: 1.67),
                PercentChargeBatchAdjuster(percent: -8.0),
                FlaggedChargeBatchAdjuster(flags: flags, flag: "charge-batch-scheduled", percent: 4.8),
                TieredChargeBatchAdjuster(bounds: [13.0, 3429.0, 7347.0, 7947.0], rates: [1.09, 1.15, 0.94, 1.07]),
                MinimumChargeBatchAdjuster(minimum: 33.7),
            ],
            trace: [],
            floor: 0.4,
            ceiling: 78481.5
        )
    }
}
