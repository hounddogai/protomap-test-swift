import AcmePlatform
import Foundation

extension Referrals {
    /// One step of the pending referral ledger calculation.
    protocol PendingReferralLedgerFactor {
        func describe() -> String
        func adjust(_ item: PendingReferralLedger, value: Double) -> Double
    }

    final class PendingReferralLedgerRetriesOffsetAdjuster: PendingReferralLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus retries times \(weight)"
        }

        func adjust(_ item: PendingReferralLedger, value: Double) -> Double {
            return value + Double(item.retries) * weight
        }
    }

    final class PercentPendingReferralLedgerAdjuster: PendingReferralLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingReferralLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapPendingReferralLedgerAdjuster: PendingReferralLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingReferralLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RoundingPendingReferralLedgerAdjuster: PendingReferralLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: PendingReferralLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class TieredPendingReferralLedgerAdjuster: PendingReferralLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingReferralLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    /// Runs the pending referral ledger steps in order and keeps a trace of each.
    final class PendingReferralLedgerEngine {
        var steps: [any PendingReferralLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingReferralLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingReferralLedger) -> Double {
            var current = item.netLoad()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingReferralLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [PendingReferralLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingReferralLedgerEngine() -> PendingReferralLedgerEngine {
        return PendingReferralLedgerEngine(
            steps: [
                PendingReferralLedgerRetriesOffsetAdjuster(weight: 0.26),
                PercentPendingReferralLedgerAdjuster(percent: -11.1),
                CapPendingReferralLedgerAdjuster(cap: 25698.0),
                RoundingPendingReferralLedgerAdjuster(step: 0.05),
                TieredPendingReferralLedgerAdjuster(bounds: [1266.0, 3359.0, 8247.0], rates: [1.06, 1.12, 1.08]),
            ],
            trace: [],
            floor: 2.0,
            ceiling: 1002.7
        )
    }
}
