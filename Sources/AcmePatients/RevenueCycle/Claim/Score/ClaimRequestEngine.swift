import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim request calculation.
    protocol ClaimRequestStep {
        func describe() -> String
        func adjust(_ item: ClaimRequest, value: Double) -> Double
    }

    final class CapClaimRequestAdjuster: ClaimRequestStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimRequest, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FacilityClaimRequestAdjuster: ClaimRequestStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by facility"
        }

        func adjust(_ item: ClaimRequest, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedClaimRequestAdjuster: ClaimRequestStep {
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

        func adjust(_ item: ClaimRequest, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredClaimRequestAdjuster: ClaimRequestStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: ClaimRequest, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentClaimRequestAdjuster: ClaimRequestStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ClaimRequest, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class MinimumClaimRequestAdjuster: ClaimRequestStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimRequest, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the claim request steps in order and keeps a trace of each.
    final class ClaimRequestEngine {
        var steps: [any ClaimRequestStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimRequestStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ClaimRequest) -> Double {
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

        func evaluateAll(_ items: [ClaimRequest]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultClaimRequestEngine(_ flags: Kit.Flags.Registry) -> ClaimRequestEngine {
        return ClaimRequestEngine(
            steps: [
                CapClaimRequestAdjuster(cap: 3040.0),
                FacilityClaimRequestAdjuster(factors: ["retail": 0.86]),
                FlaggedClaimRequestAdjuster(flags: flags, flag: "claim-request-legacy", percent: 7.3),
                TieredClaimRequestAdjuster(bounds: [2409.0, 8410.0], rates: [1.06, 0.84]),
                PercentClaimRequestAdjuster(percent: 7.9),
                MinimumClaimRequestAdjuster(minimum: 46.8),
            ],
            trace: [],
            floor: 0.3,
            ceiling: 47675.0
        )
    }
}
