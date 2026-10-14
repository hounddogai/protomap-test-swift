import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the capped worklist notice calculation.
    protocol CappedWorklistNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: CappedWorklistNotice, value: Double) -> Double
    }

    final class PercentCappedWorklistNoticeAdjuster: CappedWorklistNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CappedWorklistNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelCappedWorklistNoticeAdjuster: CappedWorklistNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: CappedWorklistNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapCappedWorklistNoticeAdjuster: CappedWorklistNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedWorklistNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCappedWorklistNoticeAdjuster: CappedWorklistNoticeAdjuster {
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

        func adjust(_ item: CappedWorklistNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CappedWorklistNoticeMarginOffsetAdjuster: CappedWorklistNoticeAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus margin times \(weight)"
        }

        func adjust(_ item: CappedWorklistNotice, value: Double) -> Double {
            return value + item.margin * weight
        }
    }

    /// Runs the capped worklist notice steps in order and keeps a trace of each.
    final class CappedWorklistNoticeEngine {
        var steps: [any CappedWorklistNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedWorklistNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: CappedWorklistNotice) -> Double {
            var current = item.adjustedTotal()
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

        func evaluateAll(_ items: [CappedWorklistNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultCappedWorklistNoticeEngine(_ flags: Kit.Flags.Registry) -> CappedWorklistNoticeEngine {
        return CappedWorklistNoticeEngine(
            steps: [
                PercentCappedWorklistNoticeAdjuster(percent: 6.3),
                LabelCappedWorklistNoticeAdjuster(factors: ["north": 1.05]),
                CapCappedWorklistNoticeAdjuster(cap: 34724.0),
                FlaggedCappedWorklistNoticeAdjuster(
                    flags: flags,
                    flag: "capped-worklist-notice-lenient",
                    percent: -6.6
                ),
                CappedWorklistNoticeMarginOffsetAdjuster(weight: 1.12),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 14238.4
        )
    }
}
