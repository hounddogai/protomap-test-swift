import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the seasonal slot notice calculation.
    protocol SeasonalSlotNoticeFactor {
        func describe() -> String
        func adjust(_ item: SeasonalSlotNotice, value: Double) -> Double
    }

    final class PercentSeasonalSlotNoticeAdjuster: SeasonalSlotNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: SeasonalSlotNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapSeasonalSlotNoticeAdjuster: SeasonalSlotNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: SeasonalSlotNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class LabelSeasonalSlotNoticeAdjuster: SeasonalSlotNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: SeasonalSlotNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class SeasonalSlotNoticeStartsAtOffsetAdjuster: SeasonalSlotNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus starts at times \(weight)"
        }

        func adjust(_ item: SeasonalSlotNotice, value: Double) -> Double {
            return value + Double(item.startsAt) * weight
        }
    }

    final class FlaggedSeasonalSlotNoticeAdjuster: SeasonalSlotNoticeFactor {
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

        func adjust(_ item: SeasonalSlotNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the seasonal slot notice steps in order and keeps a trace of each.
    final class SeasonalSlotNoticeEngine {
        var steps: [any SeasonalSlotNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any SeasonalSlotNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: SeasonalSlotNotice) -> Double {
            var current = item.netTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any SeasonalSlotNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [SeasonalSlotNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultSeasonalSlotNoticeEngine(_ flags: Kit.Flags.Registry) -> SeasonalSlotNoticeEngine {
        return SeasonalSlotNoticeEngine(
            steps: [
                PercentSeasonalSlotNoticeAdjuster(percent: 10.0),
                CapSeasonalSlotNoticeAdjuster(cap: 32238.0),
                LabelSeasonalSlotNoticeAdjuster(factors: ["east": 0.73, "retail": 1.24]),
                SeasonalSlotNoticeStartsAtOffsetAdjuster(weight: 1.65),
                FlaggedSeasonalSlotNoticeAdjuster(flags: flags, flag: "seasonal-slot-notice-rolling", percent: -5.3),
            ],
            trace: [],
            floor: 1.8,
            ceiling: 72277.5
        )
    }
}
