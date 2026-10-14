import AcmePlatform
import Foundation

extension Pharmacy {
    /// One step of the primary substitution notice calculation.
    protocol PrimarySubstitutionNoticeFactor {
        func describe() -> String
        func adjust(_ item: PrimarySubstitutionNotice, value: Double) -> Double
    }

    final class PercentPrimarySubstitutionNoticeAdjuster: PrimarySubstitutionNoticeFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PrimarySubstitutionNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PrimarySubstitutionNoticeWindowDaysOffsetAdjuster: PrimarySubstitutionNoticeFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus window days times \(weight)"
        }

        func adjust(_ item: PrimarySubstitutionNotice, value: Double) -> Double {
            return value + Double(item.windowDays) * weight
        }
    }

    final class FlaggedPrimarySubstitutionNoticeAdjuster: PrimarySubstitutionNoticeFactor {
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

        func adjust(_ item: PrimarySubstitutionNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPrimarySubstitutionNoticeAdjuster: PrimarySubstitutionNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimarySubstitutionNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the primary substitution notice steps in order and keeps a trace of each.
    final class PrimarySubstitutionNoticeEngine {
        var steps: [any PrimarySubstitutionNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimarySubstitutionNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: PrimarySubstitutionNotice) -> Double {
            var current = item.projectedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimarySubstitutionNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [PrimarySubstitutionNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultPrimarySubstitutionNoticeEngine(_ flags: Kit.Flags.Registry) -> PrimarySubstitutionNoticeEngine {
        return PrimarySubstitutionNoticeEngine(
            steps: [
                PercentPrimarySubstitutionNoticeAdjuster(percent: -4.0),
                PrimarySubstitutionNoticeWindowDaysOffsetAdjuster(weight: 0.42),
                FlaggedPrimarySubstitutionNoticeAdjuster(
                    flags: flags,
                    flag: "primary-substitution-notice-fallback",
                    percent: 4.6
                ),
                TieredPrimarySubstitutionNoticeAdjuster(bounds: [934.0, 1639.0], rates: [1.13, 0.82]),
            ],
            trace: [],
            floor: 0.1,
            ceiling: 76001.7
        )
    }
}
