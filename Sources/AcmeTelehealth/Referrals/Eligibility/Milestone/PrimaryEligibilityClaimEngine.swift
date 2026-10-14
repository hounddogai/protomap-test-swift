import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the primary eligibility claim calculation.
    protocol PrimaryEligibilityClaimAdjuster {
        func describe() -> String
        func adjust(_ item: PrimaryEligibilityClaim, value: Double) -> Double
    }

    final class TieredPrimaryEligibilityClaimAdjuster: PrimaryEligibilityClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PrimaryEligibilityClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapPrimaryEligibilityClaimAdjuster: PrimaryEligibilityClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PrimaryEligibilityClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PrimaryEligibilityClaimCeilingOffsetAdjuster: PrimaryEligibilityClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus ceiling times \(weight)"
        }

        func adjust(_ item: PrimaryEligibilityClaim, value: Double) -> Double {
            return value + item.ceiling * weight
        }
    }

    final class FlaggedPrimaryEligibilityClaimAdjuster: PrimaryEligibilityClaimAdjuster {
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

        func adjust(_ item: PrimaryEligibilityClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the primary eligibility claim steps in order and keeps a trace of each.
    final class PrimaryEligibilityClaimEngine {
        var steps: [any PrimaryEligibilityClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PrimaryEligibilityClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: PrimaryEligibilityClaim) -> Double {
            var current = item.effectiveVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any PrimaryEligibilityClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [PrimaryEligibilityClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultPrimaryEligibilityClaimEngine(_ flags: Kit.Flags.Registry) -> PrimaryEligibilityClaimEngine {
        return PrimaryEligibilityClaimEngine(
            steps: [
                TieredPrimaryEligibilityClaimAdjuster(
                    bounds: [1987.0, 4106.0, 4248.0, 6056.0],
                    rates: [1.0, 1.19, 1.15, 1.0]
                ),
                CapPrimaryEligibilityClaimAdjuster(cap: 23063.0),
                PrimaryEligibilityClaimCeilingOffsetAdjuster(weight: 1.28),
                FlaggedPrimaryEligibilityClaimAdjuster(
                    flags: flags,
                    flag: "primary-eligibility-claim-scheduled",
                    percent: 1.2
                ),
            ],
            trace: [],
            floor: 0.9,
            ceiling: 58768.8
        )
    }
}
