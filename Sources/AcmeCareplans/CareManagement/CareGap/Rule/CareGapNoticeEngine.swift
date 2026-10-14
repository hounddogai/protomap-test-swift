import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the care gap notice calculation.
    protocol CareGapNoticeModifier {
        func describe() -> String
        func adjust(_ item: CareGapNotice, value: Double) -> Double
    }

    final class PercentCareGapNoticeAdjuster: CareGapNoticeModifier {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareGapNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedCareGapNoticeAdjuster: CareGapNoticeModifier {
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

        func adjust(_ item: CareGapNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapCareGapNoticeAdjuster: CareGapNoticeModifier {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareGapNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumCareGapNoticeAdjuster: CareGapNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: CareGapNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the care gap notice steps in order and keeps a trace of each.
    final class CareGapNoticeEngine {
        var steps: [any CareGapNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareGapNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CareGapNotice) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareGapNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [CareGapNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCareGapNoticeEngine(_ flags: Kit.Flags.Registry) -> CareGapNoticeEngine {
        return CareGapNoticeEngine(
            steps: [
                PercentCareGapNoticeAdjuster(percent: -18.6),
                FlaggedCareGapNoticeAdjuster(flags: flags, flag: "care-gap-notice-tiered", percent: 1.0),
                CapCareGapNoticeAdjuster(cap: 5930.0),
                MinimumCareGapNoticeAdjuster(minimum: 16.8),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 17911.1
        )
    }
}
