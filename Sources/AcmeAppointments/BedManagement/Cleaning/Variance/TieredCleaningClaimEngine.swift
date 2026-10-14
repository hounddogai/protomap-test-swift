import AcmePlatform
import Foundation

extension BedManagement {
    /// One step of the tiered cleaning claim calculation.
    protocol TieredCleaningClaimStep {
        func describe() -> String
        func adjust(_ item: TieredCleaningClaim, value: Double) -> Double
    }

    final class FlaggedTieredCleaningClaimAdjuster: TieredCleaningClaimStep {
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

        func adjust(_ item: TieredCleaningClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LabelTieredCleaningClaimAdjuster: TieredCleaningClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by label"
        }

        func adjust(_ item: TieredCleaningClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapTieredCleaningClaimAdjuster: TieredCleaningClaimStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: TieredCleaningClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumTieredCleaningClaimAdjuster: TieredCleaningClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: TieredCleaningClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class TieredTieredCleaningClaimAdjuster: TieredCleaningClaimStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: TieredCleaningClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the tiered cleaning claim steps in order and keeps a trace of each.
    final class TieredCleaningClaimEngine {
        var steps: [any TieredCleaningClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any TieredCleaningClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: TieredCleaningClaim) -> Double {
            var current = item.effectiveExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any TieredCleaningClaimStep = steps[index]
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

        func evaluateAll(_ items: [TieredCleaningClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultTieredCleaningClaimEngine(_ flags: Kit.Flags.Registry) -> TieredCleaningClaimEngine {
        return TieredCleaningClaimEngine(
            steps: [
                FlaggedTieredCleaningClaimAdjuster(flags: flags, flag: "tiered-cleaning-claim-strict", percent: -0.9),
                LabelTieredCleaningClaimAdjuster(factors: ["south": 1.31]),
                CapTieredCleaningClaimAdjuster(cap: 40163.0),
                MinimumTieredCleaningClaimAdjuster(minimum: 32.4),
                TieredTieredCleaningClaimAdjuster(
                    bounds: [4492.0, 5093.0, 6082.0, 9563.0],
                    rates: [0.92, 0.81, 1.17, 0.81]
                ),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 64455.9
        )
    }
}
