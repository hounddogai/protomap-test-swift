import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the capped care gap claim calculation.
    protocol CappedCareGapClaimAdjuster {
        func describe() -> String
        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double
    }

    final class FlaggedCappedCareGapClaimAdjuster: CappedCareGapClaimAdjuster {
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

        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredCappedCareGapClaimAdjuster: CappedCareGapClaimAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class CapCappedCareGapClaimAdjuster: CappedCareGapClaimAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class CappedCareGapClaimQuantityOffsetAdjuster: CappedCareGapClaimAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus quantity times \(weight)"
        }

        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double {
            return value + Double(item.quantity) * weight
        }
    }

    final class LocaleCappedCareGapClaimAdjuster: CappedCareGapClaimAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingCappedCareGapClaimAdjuster: CappedCareGapClaimAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedCareGapClaim, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped care gap claim steps in order and keeps a trace of each.
    final class CappedCareGapClaimEngine {
        var steps: [any CappedCareGapClaimAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedCareGapClaimAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: CappedCareGapClaim) -> Double {
            var current = item.weightedExposure()
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

        func evaluateAll(_ items: [CappedCareGapClaim]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultCappedCareGapClaimEngine(_ flags: Kit.Flags.Registry) -> CappedCareGapClaimEngine {
        return CappedCareGapClaimEngine(
            steps: [
                FlaggedCappedCareGapClaimAdjuster(flags: flags, flag: "capped-care-gap-claim-batched", percent: 0.1),
                TieredCappedCareGapClaimAdjuster(bounds: [3324.0, 6811.0], rates: [1.05, 1.17]),
                CapCappedCareGapClaimAdjuster(cap: 17893.0),
                CappedCareGapClaimQuantityOffsetAdjuster(weight: 0.21),
                LocaleCappedCareGapClaimAdjuster(factors: ["online": 0.8, "retail": 0.75, "east": 0.83]),
                RoundingCappedCareGapClaimAdjuster(step: 0.25),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 89606.2
        )
    }
}
