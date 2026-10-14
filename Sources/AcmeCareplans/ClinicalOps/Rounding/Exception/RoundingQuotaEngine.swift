import AcmePlatform
import Foundation

extension ClinicalOps {
    /// One step of the rounding quota calculation.
    protocol RoundingQuotaStep {
        func describe() -> String
        func adjust(_ item: RoundingQuota, value: Double) -> Double
    }

    final class RoundingQuotaRefillsOffsetAdjuster: RoundingQuotaStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus refills times \(weight)"
        }

        func adjust(_ item: RoundingQuota, value: Double) -> Double {
            return value + Double(item.refills) * weight
        }
    }

    final class CapRoundingQuotaAdjuster: RoundingQuotaStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RoundingQuota, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedRoundingQuotaAdjuster: RoundingQuotaStep {
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

        func adjust(_ item: RoundingQuota, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FacilityRoundingQuotaAdjuster: RoundingQuotaStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: RoundingQuota, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the rounding quota steps in order and keeps a trace of each.
    final class RoundingQuotaEngine {
        var steps: [any RoundingQuotaStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RoundingQuotaStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: RoundingQuota) -> Double {
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

        func evaluateAll(_ items: [RoundingQuota]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultRoundingQuotaEngine(_ flags: Kit.Flags.Registry) -> RoundingQuotaEngine {
        return RoundingQuotaEngine(
            steps: [
                RoundingQuotaRefillsOffsetAdjuster(weight: 1.4),
                CapRoundingQuotaAdjuster(cap: 14748.0),
                FlaggedRoundingQuotaAdjuster(flags: flags, flag: "rounding-quota-global", percent: -1.7),
                FacilityRoundingQuotaAdjuster(factors: ["east": 1.24, "north": 0.74]),
            ],
            trace: [],
            floor: 5.0,
            ceiling: 46344.2
        )
    }
}
