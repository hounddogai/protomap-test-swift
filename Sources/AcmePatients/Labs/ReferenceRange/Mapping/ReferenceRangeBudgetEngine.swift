import AcmePlatform
import Foundation

extension Labs {
    /// One step of the reference range budget calculation.
    protocol ReferenceRangeBudgetAdjuster {
        func describe() -> String
        func adjust(_ item: ReferenceRangeBudget, value: Double) -> Double
    }

    final class FlaggedReferenceRangeBudgetAdjuster: ReferenceRangeBudgetAdjuster {
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

        func adjust(_ item: ReferenceRangeBudget, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ReferenceRangeBudgetBatchSizeOffsetAdjuster: ReferenceRangeBudgetAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: ReferenceRangeBudget, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class TieredReferenceRangeBudgetAdjuster: ReferenceRangeBudgetAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ReferenceRangeBudget, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the reference range budget steps in order and keeps a trace of each.
    final class ReferenceRangeBudgetEngine {
        var steps: [any ReferenceRangeBudgetAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReferenceRangeBudgetAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ReferenceRangeBudget) -> Double {
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

        func evaluateAll(_ items: [ReferenceRangeBudget]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultReferenceRangeBudgetEngine(_ flags: Kit.Flags.Registry) -> ReferenceRangeBudgetEngine {
        return ReferenceRangeBudgetEngine(
            steps: [
                FlaggedReferenceRangeBudgetAdjuster(
                    flags: flags,
                    flag: "reference-range-budget-pending",
                    percent: -7.6
                ),
                ReferenceRangeBudgetBatchSizeOffsetAdjuster(weight: 0.43),
                TieredReferenceRangeBudgetAdjuster(bounds: [56.0, 224.0], rates: [1.15, 1.13]),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 37884.2
        )
    }
}
