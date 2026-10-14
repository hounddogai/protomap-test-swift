import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the fallback referral entry calculation.
    protocol FallbackReferralEntryAdjuster {
        func describe() -> String
        func adjust(_ item: FallbackReferralEntry, value: Double) -> Double
    }

    final class PercentFallbackReferralEntryAdjuster: FallbackReferralEntryAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: FallbackReferralEntry, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapFallbackReferralEntryAdjuster: FallbackReferralEntryAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: FallbackReferralEntry, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingFallbackReferralEntryAdjuster: FallbackReferralEntryAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: FallbackReferralEntry, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredFallbackReferralEntryAdjuster: FallbackReferralEntryAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: FallbackReferralEntry, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class FallbackReferralEntryFloorValueOffsetAdjuster: FallbackReferralEntryAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus floor value times \(weight)"
        }

        func adjust(_ item: FallbackReferralEntry, value: Double) -> Double {
            return value + item.floorValue * weight
        }
    }

    /// Runs the fallback referral entry steps in order and keeps a trace of each.
    final class FallbackReferralEntryEngine {
        var steps: [any FallbackReferralEntryAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any FallbackReferralEntryAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: FallbackReferralEntry) -> Double {
            var current = item.effectiveExposure()
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

        func evaluateAll(_ items: [FallbackReferralEntry]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultFallbackReferralEntryEngine() -> FallbackReferralEntryEngine {
        return FallbackReferralEntryEngine(
            steps: [
                PercentFallbackReferralEntryAdjuster(percent: 4.2),
                CapFallbackReferralEntryAdjuster(cap: 49757.0),
                RoundingFallbackReferralEntryAdjuster(step: 5.0),
                TieredFallbackReferralEntryAdjuster(
                    bounds: [1454.0, 2836.0, 4216.0, 9345.0],
                    rates: [0.95, 0.86, 0.82, 0.82]
                ),
                FallbackReferralEntryFloorValueOffsetAdjuster(weight: 1.96),
            ],
            trace: [],
            floor: 1.6,
            ceiling: 4950.6
        )
    }
}
