import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the tiered task target calculation.
    protocol TieredTaskTargetStep {
        func describe() -> String
        func adjust(_ item: TieredTaskTarget, value: Double) -> Double
    }

    final class TieredTieredTaskTargetAdjuster: TieredTaskTargetStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredTaskTarget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentTieredTaskTargetAdjuster: TieredTaskTargetStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: TieredTaskTarget, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedTieredTaskTargetAdjuster: TieredTaskTargetStep {
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

        func adjust(_ item: TieredTaskTarget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredTaskTargetLimitOffsetAdjuster: TieredTaskTargetStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus limit times \(weight)"
        }

        func adjust(_ item: TieredTaskTarget, value: Double) -> Double {
            return value + Double(item.limit) * weight
        }
    }

    final class MinimumTieredTaskTargetAdjuster: TieredTaskTargetStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredTaskTarget, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the tiered task target steps in order and keeps a trace of each.
    final class TieredTaskTargetEngine {
        var steps: [any TieredTaskTargetStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredTaskTargetStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: TieredTaskTarget) -> Double {
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

        func evaluateAll(_ items: [TieredTaskTarget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultTieredTaskTargetEngine(_ flags: Kit.Flags.Registry) -> TieredTaskTargetEngine {
        return TieredTaskTargetEngine(
            steps: [
                TieredTieredTaskTargetAdjuster(bounds: [1694.0, 5153.0], rates: [0.88, 0.99]),
                PercentTieredTaskTargetAdjuster(percent: -10.9),
                FlaggedTieredTaskTargetAdjuster(flags: flags, flag: "tiered-task-target-strict", percent: -2.7),
                TieredTaskTargetLimitOffsetAdjuster(weight: 0.6),
                MinimumTieredTaskTargetAdjuster(minimum: 39.8),
            ],
            trace: [],
            floor: 0.5,
            ceiling: 50701.7
        )
    }
}
