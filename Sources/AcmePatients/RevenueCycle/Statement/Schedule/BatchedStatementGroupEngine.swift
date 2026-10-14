import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the batched statement group calculation.
    protocol BatchedStatementGroupStep {
        func describe() -> String
        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double
    }

    final class MinimumBatchedStatementGroupAdjuster: BatchedStatementGroupStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class PercentBatchedStatementGroupAdjuster: BatchedStatementGroupStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedBatchedStatementGroupAdjuster: BatchedStatementGroupStep {
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

        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityBatchedStatementGroupAdjuster: BatchedStatementGroupStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class BatchedStatementGroupAttemptsOffsetAdjuster: BatchedStatementGroupStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus attempts times \(weight)"
        }

        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double {
            return value + Double(item.attempts) * weight
        }
    }

    final class RoundingBatchedStatementGroupAdjuster: BatchedStatementGroupStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedStatementGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched statement group steps in order and keeps a trace of each.
    final class BatchedStatementGroupEngine {
        var steps: [any BatchedStatementGroupStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedStatementGroupStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: BatchedStatementGroup) -> Double {
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

        func evaluateAll(_ items: [BatchedStatementGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultBatchedStatementGroupEngine(_ flags: Kit.Flags.Registry) -> BatchedStatementGroupEngine {
        return BatchedStatementGroupEngine(
            steps: [
                MinimumBatchedStatementGroupAdjuster(minimum: 10.2),
                PercentBatchedStatementGroupAdjuster(percent: -24.9),
                FlaggedBatchedStatementGroupAdjuster(
                    flags: flags,
                    flag: "batched-statement-group-scheduled",
                    percent: 8.3
                ),
                FacilityBatchedStatementGroupAdjuster(factors: ["east": 1.3, "south": 0.85]),
                BatchedStatementGroupAttemptsOffsetAdjuster(weight: 0.81),
                RoundingBatchedStatementGroupAdjuster(step: 0.05),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 48216.9
        )
    }
}
