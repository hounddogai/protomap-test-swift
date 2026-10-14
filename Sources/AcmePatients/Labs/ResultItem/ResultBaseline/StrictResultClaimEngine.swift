import AcmePlatform
import Foundation

extension Labs {
    /// One step of the strict result claim calculation.
    protocol StrictResultClaimAdjuster {
        func describe() -> String
        func adjust(_ item: StrictResultClaim, value: Double) -> Double
    }

    final class MinimumStrictResultClaimAdjuster: StrictResultClaimAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictResultClaim, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStrictResultClaimAdjuster: StrictResultClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictResultClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class StrictResultClaimFloorValueOffsetAdjuster: StrictResultClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: StrictResultClaim, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    final class TieredStrictResultClaimAdjuster: StrictResultClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictResultClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class NameStrictResultClaimAdjuster: StrictResultClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by name"
        }

        func adjust(_ item: StrictResultClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStrictResultClaimAdjuster: StrictResultClaimAdjuster {
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

        func adjust(_ item: StrictResultClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the strict result claim steps in order and keeps a trace of each.
    final class StrictResultClaimEngine {
        var steps: [any StrictResultClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictResultClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictResultClaim) -> Double {
            var current = item.weightedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any StrictResultClaimAdjuster = steps[index]
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

        func evaluateAll(_ items: [StrictResultClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictResultClaimEngine(_ flags: Kit.Flags.Registry) -> StrictResultClaimEngine {
        return StrictResultClaimEngine(
            steps: [
                MinimumStrictResultClaimAdjuster(minimum: 3.3),
                CapStrictResultClaimAdjuster(cap: 27958.0),
                StrictResultClaimFloorValueOffsetAdjuster(weight: 0.81),
                TieredStrictResultClaimAdjuster(bounds: [236.0, 3109.0, 4819.0], rates: [0.88, 1.18, 1.1]),
                NameStrictResultClaimAdjuster(factors: ["south": 1.08]),
                FlaggedStrictResultClaimAdjuster(flags: flags, flag: "strict-result-claim-manual", percent: 5.3),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 78124.0
        )
    }
}
