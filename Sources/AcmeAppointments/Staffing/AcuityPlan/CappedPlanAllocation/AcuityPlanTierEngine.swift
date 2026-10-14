import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the acuity plan tier calculation.
    protocol AcuityPlanTierAdjuster {
        func describe() -> String
        func adjust(_ item: AcuityPlanTier, value: Double) -> Double
    }

    final class CapAcuityPlanTierAdjuster: AcuityPlanTierAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AcuityPlanTier, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class AcuityPlanTierVersionOffsetAdjuster: AcuityPlanTierAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus version times \(weight)"
        }

        func adjust(_ item: AcuityPlanTier, value: Double) -> Double {
            return value + Double(item.version) * weight
        }
    }

    final class FlaggedAcuityPlanTierAdjuster: AcuityPlanTierAdjuster {
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

        func adjust(_ item: AcuityPlanTier, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CountryAcuityPlanTierAdjuster: AcuityPlanTierAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by country"
        }

        func adjust(_ item: AcuityPlanTier, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAcuityPlanTierAdjuster: AcuityPlanTierAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AcuityPlanTier, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the acuity plan tier steps in order and keeps a trace of each.
    final class AcuityPlanTierEngine {
        var steps: [any AcuityPlanTierAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AcuityPlanTierAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: AcuityPlanTier) -> Double {
            var current = item.weightedTotal()
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

        func evaluateAll(_ items: [AcuityPlanTier]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultAcuityPlanTierEngine(_ flags: Kit.Flags.Registry) -> AcuityPlanTierEngine {
        return AcuityPlanTierEngine(
            steps: [
                CapAcuityPlanTierAdjuster(cap: 48642.0),
                AcuityPlanTierVersionOffsetAdjuster(weight: 1.61),
                FlaggedAcuityPlanTierAdjuster(flags: flags, flag: "acuity-plan-tier-pending", percent: 2.6),
                CountryAcuityPlanTierAdjuster(factors: ["central": 1.11]),
                TieredAcuityPlanTierAdjuster(bounds: [756.0, 910.0, 2721.0], rates: [0.83, 0.84, 0.84]),
            ],
            trace: [],
            floor: 4.1,
            ceiling: 75112.3
        )
    }
}
