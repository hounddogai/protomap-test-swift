import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the adaptive acuity plan claim calculation.
    protocol AdaptiveAcuityPlanClaimFactor {
        func describe() -> String
        func adjust(_ item: AdaptiveAcuityPlanClaim, value: Double) -> Double
    }

    final class CapAdaptiveAcuityPlanClaimAdjuster: AdaptiveAcuityPlanClaimFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: AdaptiveAcuityPlanClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumAdaptiveAcuityPlanClaimAdjuster: AdaptiveAcuityPlanClaimFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: AdaptiveAcuityPlanClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedAdaptiveAcuityPlanClaimAdjuster: AdaptiveAcuityPlanClaimFactor {
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

        func adjust(_ item: AdaptiveAcuityPlanClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class SegmentAdaptiveAcuityPlanClaimAdjuster: AdaptiveAcuityPlanClaimFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: AdaptiveAcuityPlanClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class TieredAdaptiveAcuityPlanClaimAdjuster: AdaptiveAcuityPlanClaimFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: AdaptiveAcuityPlanClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the adaptive acuity plan claim steps in order and keeps a trace of each.
    final class AdaptiveAcuityPlanClaimEngine {
        var steps: [any AdaptiveAcuityPlanClaimFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any AdaptiveAcuityPlanClaimFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: AdaptiveAcuityPlanClaim) -> Double {
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

        func evaluateAll(_ items: [AdaptiveAcuityPlanClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultAdaptiveAcuityPlanClaimEngine(_ flags: Kit.Flags.Registry) -> AdaptiveAcuityPlanClaimEngine {
        return AdaptiveAcuityPlanClaimEngine(
            steps: [
                CapAdaptiveAcuityPlanClaimAdjuster(cap: 27426.0),
                MinimumAdaptiveAcuityPlanClaimAdjuster(minimum: 42.4),
                FlaggedAdaptiveAcuityPlanClaimAdjuster(
                    flags: flags,
                    flag: "adaptive-acuity-plan-claim-batched",
                    percent: 0.1
                ),
                SegmentAdaptiveAcuityPlanClaimAdjuster(factors: ["west": 0.7, "north": 1.19]),
                TieredAdaptiveAcuityPlanClaimAdjuster(bounds: [520.0, 1206.0, 8563.0], rates: [0.83, 1.2, 0.98]),
            ],
            trace: [],
            floor: 2.1,
            ceiling: 4578.9
        )
    }
}
