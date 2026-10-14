import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the rolling slot agreement calculation.
    protocol RollingSlotAgreementStep {
        func describe() -> String
        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double
    }

    final class TieredRollingSlotAgreementAdjuster: RollingSlotAgreementStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingRollingSlotAgreementAdjuster: RollingSlotAgreementStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class PercentRollingSlotAgreementAdjuster: RollingSlotAgreementStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapRollingSlotAgreementAdjuster: RollingSlotAgreementStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRollingSlotAgreementAdjuster: RollingSlotAgreementStep {
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

        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRollingSlotAgreementAdjuster: RollingSlotAgreementStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingSlotAgreement, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling slot agreement steps in order and keeps a trace of each.
    final class RollingSlotAgreementEngine {
        var steps: [any RollingSlotAgreementStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingSlotAgreementStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RollingSlotAgreement) -> Double {
            var current = item.netValue()
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

        func evaluateAll(_ items: [RollingSlotAgreement]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRollingSlotAgreementEngine(_ flags: Kit.Flags.Registry) -> RollingSlotAgreementEngine {
        return RollingSlotAgreementEngine(
            steps: [
                TieredRollingSlotAgreementAdjuster(bounds: [3442.0, 5130.0], rates: [0.87, 1.06]),
                RoundingRollingSlotAgreementAdjuster(step: 0.5),
                PercentRollingSlotAgreementAdjuster(percent: 1.4),
                CapRollingSlotAgreementAdjuster(cap: 2193.0),
                FlaggedRollingSlotAgreementAdjuster(
                    flags: flags,
                    flag: "rolling-slot-agreement-default",
                    percent: -1.4
                ),
                NameRollingSlotAgreementAdjuster(factors: ["retail": 0.73, "central": 1.07]),
            ],
            trace: [],
            floor: 2.8,
            ceiling: 6923.6
        )
    }
}
