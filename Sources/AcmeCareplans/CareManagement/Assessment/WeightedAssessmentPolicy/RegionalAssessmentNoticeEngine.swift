import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the regional assessment notice calculation.
    protocol RegionalAssessmentNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: RegionalAssessmentNotice, value: Double) -> Double
    }

    final class PercentRegionalAssessmentNoticeAdjuster: RegionalAssessmentNoticeAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RegionalAssessmentNotice, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedRegionalAssessmentNoticeAdjuster: RegionalAssessmentNoticeAdjuster {
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

        func adjust(_ item: RegionalAssessmentNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityRegionalAssessmentNoticeAdjuster: RegionalAssessmentNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RegionalAssessmentNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapRegionalAssessmentNoticeAdjuster: RegionalAssessmentNoticeAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalAssessmentNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the regional assessment notice steps in order and keeps a trace of each.
    final class RegionalAssessmentNoticeEngine {
        var steps: [any RegionalAssessmentNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAssessmentNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RegionalAssessmentNotice) -> Double {
            var current = item.effectiveVolume()
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

        func evaluateAll(_ items: [RegionalAssessmentNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRegionalAssessmentNoticeEngine(_ flags: Kit.Flags.Registry) -> RegionalAssessmentNoticeEngine {
        return RegionalAssessmentNoticeEngine(
            steps: [
                PercentRegionalAssessmentNoticeAdjuster(percent: 8.5),
                FlaggedRegionalAssessmentNoticeAdjuster(
                    flags: flags,
                    flag: "regional-assessment-notice-strict",
                    percent: -8.7
                ),
                FacilityRegionalAssessmentNoticeAdjuster(factors: ["west": 0.98, "central": 0.98]),
                CapRegionalAssessmentNoticeAdjuster(cap: 31703.0),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 75442.8
        )
    }
}
