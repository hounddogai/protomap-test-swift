import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the batched network template calculation.
    protocol BatchedNetworkTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: BatchedNetworkTemplate, value: Double) -> Double
    }

    final class FlaggedBatchedNetworkTemplateAdjuster: BatchedNetworkTemplateAdjuster {
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

        func adjust(_ item: BatchedNetworkTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class BatchedNetworkTemplateRatioOffsetAdjuster: BatchedNetworkTemplateAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ratio times \(weight)"
        }

        func adjust(_ item: BatchedNetworkTemplate, value: Double) -> Double {
            return value + item.ratio * weight
        }
    }

    final class RoundingBatchedNetworkTemplateAdjuster: BatchedNetworkTemplateAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: BatchedNetworkTemplate, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the batched network template steps in order and keeps a trace of each.
    final class BatchedNetworkTemplateEngine {
        var steps: [any BatchedNetworkTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any BatchedNetworkTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: BatchedNetworkTemplate) -> Double {
            var current = item.adjustedValue()
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

        func evaluateAll(_ items: [BatchedNetworkTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultBatchedNetworkTemplateEngine(_ flags: Kit.Flags.Registry) -> BatchedNetworkTemplateEngine {
        return BatchedNetworkTemplateEngine(
            steps: [
                FlaggedBatchedNetworkTemplateAdjuster(
                    flags: flags,
                    flag: "batched-network-template-pending",
                    percent: 3.9
                ),
                BatchedNetworkTemplateRatioOffsetAdjuster(weight: 1.61),
                RoundingBatchedNetworkTemplateAdjuster(step: 0.5),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 48324.0
        )
    }
}
