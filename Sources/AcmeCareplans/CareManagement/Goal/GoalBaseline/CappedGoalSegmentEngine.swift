import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped goal segment calculation.
    protocol CappedGoalSegmentFactor {
        func describe() -> String
        func adjust(_ item: CappedGoalSegment, value: Double) -> Double
    }

    final class PercentCappedGoalSegmentAdjuster: CappedGoalSegmentFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedGoalSegment, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingCappedGoalSegmentAdjuster: CappedGoalSegmentFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedGoalSegment, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CappedGoalSegmentBatchSizeOffsetAdjuster: CappedGoalSegmentFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus batch size times \(weight)"
        }

        func adjust(_ item: CappedGoalSegment, value: Double) -> Double {
            return value + Double(item.batchSize) * weight
        }
    }

    final class FlaggedCappedGoalSegmentAdjuster: CappedGoalSegmentFactor {
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

        func adjust(_ item: CappedGoalSegment, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedGoalSegmentAdjuster: CappedGoalSegmentFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedGoalSegment, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the capped goal segment steps in order and keeps a trace of each.
    final class CappedGoalSegmentEngine {
        var steps: [any CappedGoalSegmentFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedGoalSegmentFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedGoalSegment) -> Double {
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

        func evaluateAll(_ items: [CappedGoalSegment]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedGoalSegmentEngine(_ flags: Kit.Flags.Registry) -> CappedGoalSegmentEngine {
        return CappedGoalSegmentEngine(
            steps: [
                PercentCappedGoalSegmentAdjuster(percent: -22.2),
                RoundingCappedGoalSegmentAdjuster(step: 0.1),
                CappedGoalSegmentBatchSizeOffsetAdjuster(weight: 1.42),
                FlaggedCappedGoalSegmentAdjuster(flags: flags, flag: "capped-goal-segment-scheduled", percent: -5.9),
                TieredCappedGoalSegmentAdjuster(bounds: [4025.0, 4837.0, 9883.0], rates: [1.07, 0.87, 0.83]),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 34285.9
        )
    }
}
