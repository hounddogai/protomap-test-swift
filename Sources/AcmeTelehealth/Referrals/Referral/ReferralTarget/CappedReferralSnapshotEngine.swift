import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the capped referral snapshot calculation.
    protocol CappedReferralSnapshotAdjuster {
        func describe() -> String
        func adjust(_ item: CappedReferralSnapshot, value: Double) -> Double
    }

    final class CapCappedReferralSnapshotAdjuster: CappedReferralSnapshotAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CappedReferralSnapshot, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class TieredCappedReferralSnapshotAdjuster: CappedReferralSnapshotAdjuster {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: CappedReferralSnapshot, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class RoundingCappedReferralSnapshotAdjuster: CappedReferralSnapshotAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: CappedReferralSnapshot, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    /// Runs the capped referral snapshot steps in order and keeps a trace of each.
    final class CappedReferralSnapshotEngine {
        var steps: [any CappedReferralSnapshotAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CappedReferralSnapshotAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: CappedReferralSnapshot) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CappedReferralSnapshotAdjuster = steps[index]
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

        func evaluateAll(_ items: [CappedReferralSnapshot]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultCappedReferralSnapshotEngine() -> CappedReferralSnapshotEngine {
        return CappedReferralSnapshotEngine(
            steps: [
                CapCappedReferralSnapshotAdjuster(cap: 25339.0),
                TieredCappedReferralSnapshotAdjuster(bounds: [2809.0, 3151.0, 8140.0], rates: [0.94, 1.16, 1.02]),
                RoundingCappedReferralSnapshotAdjuster(step: 0.1),
            ],
            trace: [],
            floor: 4.9,
            ceiling: 14925.2
        )
    }
}
