import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the pending transfer notice calculation.
    protocol PendingTransferNoticeStep {
        func describe() -> String
        func adjust(_ item: PendingTransferNotice, value: Double) -> Double
    }

    final class LabelPendingTransferNoticeAdjuster: PendingTransferNoticeStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: PendingTransferNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedPendingTransferNoticeAdjuster: PendingTransferNoticeStep {
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

        func adjust(_ item: PendingTransferNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PendingTransferNoticeThresholdOffsetAdjuster: PendingTransferNoticeStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus threshold times \(weight)"
        }

        func adjust(_ item: PendingTransferNotice, value: Double) -> Double {
            return value + item.threshold * weight
        }
    }

    /// Runs the pending transfer notice steps in order and keeps a trace of each.
    final class PendingTransferNoticeEngine {
        var steps: [any PendingTransferNoticeStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingTransferNoticeStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingTransferNotice) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingTransferNoticeStep = steps[index]
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

        func evaluateAll(_ items: [PendingTransferNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingTransferNoticeEngine(_ flags: Kit.Flags.Registry) -> PendingTransferNoticeEngine {
        return PendingTransferNoticeEngine(
            steps: [
                LabelPendingTransferNoticeAdjuster(factors: ["east": 1.03]),
                FlaggedPendingTransferNoticeAdjuster(
                    flags: flags,
                    flag: "pending-transfer-notice-tiered",
                    percent: -6.9
                ),
                PendingTransferNoticeThresholdOffsetAdjuster(weight: 1.81),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 80123.0
        )
    }
}
