import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the regional acuity plan claim calculation.
    protocol RegionalAcuityPlanClaimStep {
        func describe() -> String
        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double
    }

    final class NameRegionalAcuityPlanClaimAdjuster: RegionalAcuityPlanClaimStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedRegionalAcuityPlanClaimAdjuster: RegionalAcuityPlanClaimStep {
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

        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RegionalAcuityPlanClaimScoreOffsetAdjuster: RegionalAcuityPlanClaimStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class MinimumRegionalAcuityPlanClaimAdjuster: RegionalAcuityPlanClaimStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class RoundingRegionalAcuityPlanClaimAdjuster: RegionalAcuityPlanClaimStep {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapRegionalAcuityPlanClaimAdjuster: RegionalAcuityPlanClaimStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: RegionalAcuityPlanClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the regional acuity plan claim steps in order and keeps a trace of each.
    final class RegionalAcuityPlanClaimEngine {
        var steps: [any RegionalAcuityPlanClaimStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any RegionalAcuityPlanClaimStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: RegionalAcuityPlanClaim) -> Double {
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

        func evaluateAll(_ items: [RegionalAcuityPlanClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultRegionalAcuityPlanClaimEngine(_ flags: Kit.Flags.Registry) -> RegionalAcuityPlanClaimEngine {
        return RegionalAcuityPlanClaimEngine(
            steps: [
                NameRegionalAcuityPlanClaimAdjuster(factors: ["online": 1.39, "retail": 1.27]),
                FlaggedRegionalAcuityPlanClaimAdjuster(
                    flags: flags,
                    flag: "regional-acuity-plan-claim-legacy",
                    percent: -9.3
                ),
                RegionalAcuityPlanClaimScoreOffsetAdjuster(weight: 0.25),
                MinimumRegionalAcuityPlanClaimAdjuster(minimum: 11.6),
                RoundingRegionalAcuityPlanClaimAdjuster(step: 0.25),
                CapRegionalAcuityPlanClaimAdjuster(cap: 16920.0),
            ],
            trace: [],
            floor: 3.1,
            ceiling: 19032.7
        )
    }
}
