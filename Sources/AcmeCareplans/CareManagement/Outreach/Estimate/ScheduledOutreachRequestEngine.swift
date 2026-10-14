import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the scheduled outreach request calculation.
    protocol ScheduledOutreachRequestAdjuster {
        func describe() -> String
        func adjust(_ item: ScheduledOutreachRequest, value: Double) -> Double
    }

    final class FlaggedScheduledOutreachRequestAdjuster: ScheduledOutreachRequestAdjuster {
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

        func adjust(_ item: ScheduledOutreachRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledOutreachRequestAdjuster: ScheduledOutreachRequestAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledOutreachRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class ScheduledOutreachRequestAmountOffsetAdjuster: ScheduledOutreachRequestAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: ScheduledOutreachRequest, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class LocaleScheduledOutreachRequestAdjuster: ScheduledOutreachRequestAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: ScheduledOutreachRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapScheduledOutreachRequestAdjuster: ScheduledOutreachRequestAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledOutreachRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the scheduled outreach request steps in order and keeps a trace of each.
    final class ScheduledOutreachRequestEngine {
        var steps: [any ScheduledOutreachRequestAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledOutreachRequestAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ScheduledOutreachRequest) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [ScheduledOutreachRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultScheduledOutreachRequestEngine(_ flags: Kit.Flags.Registry) -> ScheduledOutreachRequestEngine {
        return ScheduledOutreachRequestEngine(
            steps: [
                FlaggedScheduledOutreachRequestAdjuster(
                    flags: flags,
                    flag: "scheduled-outreach-request-rolling",
                    percent: -2.5
                ),
                TieredScheduledOutreachRequestAdjuster(bounds: [1990.0, 2820.0, 5849.0], rates: [1.06, 1.11, 0.98]),
                ScheduledOutreachRequestAmountOffsetAdjuster(weight: 0.43),
                LocaleScheduledOutreachRequestAdjuster(factors: ["east": 0.74]),
                CapScheduledOutreachRequestAdjuster(cap: 17072.0),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 86702.4
        )
    }
}
