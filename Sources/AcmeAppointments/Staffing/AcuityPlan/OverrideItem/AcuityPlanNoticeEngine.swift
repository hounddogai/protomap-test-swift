import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan notice calculation.
    protocol AcuityPlanNoticeFactor {
        func describe() -> String
        func adjust(_ item: AcuityPlanNotice, value: Double) -> Double
    }

    final class TieredAcuityPlanNoticeAdjuster: AcuityPlanNoticeFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanNotice, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapAcuityPlanNoticeAdjuster: AcuityPlanNoticeFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanNotice, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingAcuityPlanNoticeAdjuster: AcuityPlanNoticeFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: AcuityPlanNotice, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class LabelAcuityPlanNoticeAdjuster: AcuityPlanNoticeFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: AcuityPlanNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedAcuityPlanNoticeAdjuster: AcuityPlanNoticeFactor {
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

        func adjust(_ item: AcuityPlanNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the acuity plan notice steps in order and keeps a trace of each.
    final class AcuityPlanNoticeEngine {
        var steps: [any AcuityPlanNoticeFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanNoticeFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AcuityPlanNotice) -> Double {
            var current = item.weightedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any AcuityPlanNoticeFactor = steps[index]
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

        func evaluateAll(_ items: [AcuityPlanNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanNoticeEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanNoticeEngine {
        return AcuityPlanNoticeEngine(
            steps: [
                TieredAcuityPlanNoticeAdjuster(bounds: [2023.0, 3345.0], rates: [1.18, 1.1]),
                CapAcuityPlanNoticeAdjuster(cap: 39375.0),
                RoundingAcuityPlanNoticeAdjuster(step: 0.5),
                LabelAcuityPlanNoticeAdjuster(factors: ["south": 1.36, "online": 1.12, "retail": 1.18]),
                FlaggedAcuityPlanNoticeAdjuster(flags: flags, flag: "acuity-plan-notice-global", percent: 10.0),
            ],
            trace: [],
            floor: 2.5,
            ceiling: 54263.5
        )
    }
}
