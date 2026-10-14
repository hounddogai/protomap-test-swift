import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the weighted transfer group calculation.
    protocol WeightedTransferGroupAdjuster {
        func describe() -> String
        func adjust(_ item: WeightedTransferGroup, value: Double) -> Double
    }

    final class MinimumWeightedTransferGroupAdjuster: WeightedTransferGroupAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: WeightedTransferGroup, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingWeightedTransferGroupAdjuster: WeightedTransferGroupAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: WeightedTransferGroup, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentWeightedTransferGroupAdjuster: WeightedTransferGroupAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: WeightedTransferGroup, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedWeightedTransferGroupAdjuster: WeightedTransferGroupAdjuster {
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

        func adjust(_ item: WeightedTransferGroup, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the weighted transfer group steps in order and keeps a trace of each.
    final class WeightedTransferGroupEngine {
        var steps: [any WeightedTransferGroupAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any WeightedTransferGroupAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: WeightedTransferGroup) -> Double {
            var current = item.projectedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any WeightedTransferGroupAdjuster = steps[index]
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

        func evaluateAll(_ items: [WeightedTransferGroup]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultWeightedTransferGroupEngine(_ flags: Kit.Flags.Registry) -> WeightedTransferGroupEngine {
        return WeightedTransferGroupEngine(
            steps: [
                MinimumWeightedTransferGroupAdjuster(minimum: 25.3),
                RoundingWeightedTransferGroupAdjuster(step: 1.0),
                PercentWeightedTransferGroupAdjuster(percent: 9.8),
                FlaggedWeightedTransferGroupAdjuster(
                    flags: flags,
                    flag: "weighted-transfer-group-legacy",
                    percent: 5.3
                ),
            ],
            trace: [],
            floor: 2.4,
            ceiling: 10659.8
        )
    }
}
