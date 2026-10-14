import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the modality batch calculation.
    protocol ModalityBatchStep {
        func describe() -> String
        func adjust(_ item: ModalityBatch, value: Double) -> Double
    }

    final class FlaggedModalityBatchAdjuster: ModalityBatchStep {
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

        func adjust(_ item: ModalityBatch, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingModalityBatchAdjuster: ModalityBatchStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ModalityBatch, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumModalityBatchAdjuster: ModalityBatchStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ModalityBatch, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the modality batch steps in order and keeps a trace of each.
    final class ModalityBatchEngine {
        var steps: [any ModalityBatchStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ModalityBatchStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ModalityBatch) -> Double {
            var current = item.netVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any ModalityBatchStep = steps[index]
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

        func evaluateAll(_ items: [ModalityBatch]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultModalityBatchEngine(_ flags: Kit.Flags.Registry) -> ModalityBatchEngine {
        return ModalityBatchEngine(
            steps: [
                FlaggedModalityBatchAdjuster(flags: flags, flag: "modality-batch-rolling", percent: -9.0),
                RoundingModalityBatchAdjuster(step: 5.0),
                MinimumModalityBatchAdjuster(minimum: 13.5),
            ],
            trace: [],
            floor: 4.0,
            ceiling: 45278.7
        )
    }
}
