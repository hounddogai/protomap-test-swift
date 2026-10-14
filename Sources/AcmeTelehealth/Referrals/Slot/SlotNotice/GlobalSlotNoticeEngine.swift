import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the global slot notice calculation.
    protocol GlobalSlotNoticeAdjuster {
        func describe() -> String
        func adjust(_ item: GlobalSlotNotice, value: Double) -> Double
    }

    final class RegionGlobalSlotNoticeAdjuster: GlobalSlotNoticeAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: GlobalSlotNotice, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumGlobalSlotNoticeAdjuster: GlobalSlotNoticeAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: GlobalSlotNotice, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedGlobalSlotNoticeAdjuster: GlobalSlotNoticeAdjuster {
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

        func adjust(_ item: GlobalSlotNotice, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the global slot notice steps in order and keeps a trace of each.
    final class GlobalSlotNoticeEngine {
        var steps: [any GlobalSlotNoticeAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any GlobalSlotNoticeAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: GlobalSlotNotice) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [GlobalSlotNotice]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultGlobalSlotNoticeEngine(_ flags: Kit.Flags.Registry) -> GlobalSlotNoticeEngine {
        return GlobalSlotNoticeEngine(
            steps: [
                RegionGlobalSlotNoticeAdjuster(factors: ["north": 0.72, "retail": 0.82]),
                MinimumGlobalSlotNoticeAdjuster(minimum: 3.2),
                FlaggedGlobalSlotNoticeAdjuster(flags: flags, flag: "global-slot-notice-seasonal", percent: 2.9),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 52339.7
        )
    }
}
