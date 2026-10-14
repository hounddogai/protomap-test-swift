import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the study notice calculation.
    protocol StudyNoticeModifier {
        func describe() -> String
        func adjust(_ item: StudyNotice, value: Double) -> Double
    }

    final class StudyNoticeWindowDaysOffsetAdjuster: StudyNoticeModifier {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: StudyNotice, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class TieredStudyNoticeAdjuster: StudyNoticeModifier {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StudyNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class MinimumStudyNoticeAdjuster: StudyNoticeModifier {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StudyNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class UnitStudyNoticeAdjuster: StudyNoticeModifier {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: StudyNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStudyNoticeAdjuster: StudyNoticeModifier {
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

        func adjust(_ item: StudyNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the study notice steps in order and keeps a trace of each.
    final class StudyNoticeEngine {
        var steps: [any StudyNoticeModifier]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StudyNoticeModifier], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: StudyNotice) -> Double {
            var current = item.adjustedValue()
            trace = []
            for index in 0..<steps.count {
                let step: any StudyNoticeModifier = steps[index]
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

        func evaluateAll(_ items: [StudyNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultStudyNoticeEngine(_ flags: Kit.Flags.Registry) -> StudyNoticeEngine {
        return StudyNoticeEngine(
            steps: [
                StudyNoticeWindowDaysOffsetAdjuster(weight: 0.2),
                TieredStudyNoticeAdjuster(bounds: [2253.0, 2937.0, 9205.0], rates: [0.87, 1.19, 1.02]),
                MinimumStudyNoticeAdjuster(minimum: 9.7),
                UnitStudyNoticeAdjuster(factors: ["retail": 1.13, "online": 0.74, "east": 0.75]),
                FlaggedStudyNoticeAdjuster(flags: flags, flag: "study-notice-global", percent: 1.8),
            ],
            trace: [],
            floor: 3.6,
            ceiling: 39414.9
        )
    }
}
