import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rolling care protocol tier calculation.
    protocol RollingCareProtocolTierAdjuster {
        func describe() -> String
        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double
    }

    final class RoundingRollingCareProtocolTierAdjuster: RollingCareProtocolTierAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRollingCareProtocolTierAdjuster: RollingCareProtocolTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RollingCareProtocolTierAcuityOffsetAdjuster: RollingCareProtocolTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus acuity times \(weight)"
        }

        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double {
            return value + Double(item.acuity) * weight
        }
    }

    final class TieredRollingCareProtocolTierAdjuster: RollingCareProtocolTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FlaggedRollingCareProtocolTierAdjuster: RollingCareProtocolTierAdjuster {
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

        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class NameRollingCareProtocolTierAdjuster: RollingCareProtocolTierAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RollingCareProtocolTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rolling care protocol tier steps in order and keeps a trace of each.
    final class RollingCareProtocolTierEngine {
        var steps: [any RollingCareProtocolTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RollingCareProtocolTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: RollingCareProtocolTier) -> Double {
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

        func evaluateAll(_ items: [RollingCareProtocolTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultRollingCareProtocolTierEngine(_ flags: Kit.Flags.Registry) -> RollingCareProtocolTierEngine {
        return RollingCareProtocolTierEngine(
            steps: [
                RoundingRollingCareProtocolTierAdjuster(step: 1.0),
                CapRollingCareProtocolTierAdjuster(cap: 1819.0),
                RollingCareProtocolTierAcuityOffsetAdjuster(weight: 1.55),
                TieredRollingCareProtocolTierAdjuster(bounds: [1563.0, 4381.0], rates: [0.99, 1.07]),
                FlaggedRollingCareProtocolTierAdjuster(
                    flags: flags,
                    flag: "rolling-care-protocol-tier-legacy",
                    percent: 1.3
                ),
                NameRollingCareProtocolTierAdjuster(factors: ["retail": 1.34]),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 32658.7
        )
    }
}
