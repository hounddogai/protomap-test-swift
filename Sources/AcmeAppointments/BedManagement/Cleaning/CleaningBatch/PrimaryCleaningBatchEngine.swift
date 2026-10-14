import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the primary cleaning batch calculation.
    protocol PrimaryCleaningBatchAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryCleaningBatch, value: Double) -> Double
    }

    final class PrimaryCleaningBatchFloorValueOffsetAdjuster: PrimaryCleaningBatchAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: PrimaryCleaningBatch, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class PercentPrimaryCleaningBatchAdjuster: PrimaryCleaningBatchAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimaryCleaningBatch, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPrimaryCleaningBatchAdjuster: PrimaryCleaningBatchAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PrimaryCleaningBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedPrimaryCleaningBatchAdjuster: PrimaryCleaningBatchAdjuster {
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

        func adjust(_ item: PrimaryCleaningBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary cleaning batch steps in order and keeps a trace of each.
    final class PrimaryCleaningBatchEngine {
        var steps: [any PrimaryCleaningBatchAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryCleaningBatchAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryCleaningBatch) -> Double {
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

        func evaluateAll(_ items: [PrimaryCleaningBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryCleaningBatchEngine(_ flags: Kit.Flags.Registry) -> PrimaryCleaningBatchEngine {
        return PrimaryCleaningBatchEngine(
            steps: [
                PrimaryCleaningBatchFloorValueOffsetAdjuster(weight: 0.66),
                PercentPrimaryCleaningBatchAdjuster(percent: 18.8),
                RoundingPrimaryCleaningBatchAdjuster(step: 0.1),
                FlaggedPrimaryCleaningBatchAdjuster(
                    flags: flags,
                    flag: "primary-cleaning-batch-primary",
                    percent: 8.9
                ),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 87706.4
        )
    }
}
