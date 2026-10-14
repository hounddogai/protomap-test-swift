import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the pending care gap notice calculation.
    protocol PendingCareGapNoticeModifier {
        func describe() -> String
        func adjust(_ item: PendingCareGapNotice, value: Double) -> Double
    }

    final class FlaggedPendingCareGapNoticeAdjuster: PendingCareGapNoticeModifier {
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

        func adjust(_ item: PendingCareGapNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingPendingCareGapNoticeAdjuster: PendingCareGapNoticeModifier {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingCareGapNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapPendingCareGapNoticeAdjuster: PendingCareGapNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCareGapNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PendingCareGapNoticeRetriesOffsetAdjuster: PendingCareGapNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingCareGapNotice, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    /// Runs the pending care gap notice steps in order and keeps a trace of each.
    final class PendingCareGapNoticeEngine {
        var steps: [any PendingCareGapNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCareGapNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PendingCareGapNotice) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [PendingCareGapNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPendingCareGapNoticeEngine(_ flags: Kit.Flags.Registry) -> PendingCareGapNoticeEngine {
        return PendingCareGapNoticeEngine(
            steps: [
                FlaggedPendingCareGapNoticeAdjuster(
                    flags: flags,
                    flag: "pending-care-gap-notice-global",
                    percent: -0.3
                ),
                RoundingPendingCareGapNoticeAdjuster(step: 1.0),
                CapPendingCareGapNoticeAdjuster(cap: 5769.0),
                PendingCareGapNoticeRetriesOffsetAdjuster(weight: 0.54),
            ],
            trace: [],
            floor: 1.4,
            ceiling: 73170.2
        )
    }
}
