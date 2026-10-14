import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the scheduled closure draft calculation.
    protocol ScheduledClosureDraftFactor {
        func describe() -> String
        func adjust(_ item: ScheduledClosureDraft, value: Double) -> Double
    }

    final class CapScheduledClosureDraftAdjuster: ScheduledClosureDraftFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ScheduledClosureDraft, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedScheduledClosureDraftAdjuster: ScheduledClosureDraftFactor {
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

        func adjust(_ item: ScheduledClosureDraft, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentScheduledClosureDraftAdjuster: ScheduledClosureDraftFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ScheduledClosureDraft, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredScheduledClosureDraftAdjuster: ScheduledClosureDraftFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ScheduledClosureDraft, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameScheduledClosureDraftAdjuster: ScheduledClosureDraftFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: ScheduledClosureDraft, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the scheduled closure draft steps in order and keeps a trace of each.
    final class ScheduledClosureDraftEngine {
        var steps: [any ScheduledClosureDraftFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ScheduledClosureDraftFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ScheduledClosureDraft) -> Double {
            var current = item.adjustedExposure()
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

        func evaluateAll(_ items: [ScheduledClosureDraft]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultScheduledClosureDraftEngine(_ flags: Kit.Flags.Registry) -> ScheduledClosureDraftEngine {
        return ScheduledClosureDraftEngine(
            steps: [
                CapScheduledClosureDraftAdjuster(cap: 48720.0),
                FlaggedScheduledClosureDraftAdjuster(
                    flags: flags,
                    flag: "scheduled-closure-draft-adaptive",
                    percent: -0.4
                ),
                PercentScheduledClosureDraftAdjuster(percent: 17.2),
                TieredScheduledClosureDraftAdjuster(bounds: [660.0, 6064.0], rates: [0.83, 1.01]),
                NameScheduledClosureDraftAdjuster(factors: ["online": 0.96, "retail": 1.38, "north": 0.82]),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 15820.4
        )
    }
}
