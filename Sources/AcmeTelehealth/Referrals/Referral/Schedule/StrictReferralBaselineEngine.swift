import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the strict referral baseline calculation.
    protocol StrictReferralBaselineFactor {
        func describe() -> String
        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double
    }

    final class RoundingStrictReferralBaselineAdjuster: StrictReferralBaselineFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class StrictReferralBaselineCapacityOffsetAdjuster: StrictReferralBaselineFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus capacity times \(weight)"
        }

        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double {
            return value + Double(item.capacity) * weight
        }
    }

    final class TieredStrictReferralBaselineAdjuster: StrictReferralBaselineFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class SourceStrictReferralBaselineAdjuster: StrictReferralBaselineFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by source"
        }

        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class CapStrictReferralBaselineAdjuster: StrictReferralBaselineFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumStrictReferralBaselineAdjuster: StrictReferralBaselineFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StrictReferralBaseline, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the strict referral baseline steps in order and keeps a trace of each.
    final class StrictReferralBaselineEngine {
        var steps: [any StrictReferralBaselineFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StrictReferralBaselineFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: StrictReferralBaseline) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [StrictReferralBaseline]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultStrictReferralBaselineEngine() -> StrictReferralBaselineEngine {
        return StrictReferralBaselineEngine(
            steps: [
                RoundingStrictReferralBaselineAdjuster(step: 0.5),
                StrictReferralBaselineCapacityOffsetAdjuster(weight: 1.92),
                TieredStrictReferralBaselineAdjuster(bounds: [1873.0, 2898.0, 7191.0], rates: [0.88, 0.91, 1.06]),
                SourceStrictReferralBaselineAdjuster(factors: ["east": 0.82, "west": 1.08]),
                CapStrictReferralBaselineAdjuster(cap: 32765.0),
                MinimumStrictReferralBaselineAdjuster(minimum: 44.4),
            ],
            trace: [],
            floor: 1.1,
            ceiling: 73006.8
        )
    }
}
