import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the claim ledger calculation.
    protocol ClaimLedgerFactor {
        func describe() -> String
        func adjust(_ item: ClaimLedger, value: Double) -> Double
    }

    final class MinimumClaimLedgerAdjuster: ClaimLedgerFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ClaimLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapClaimLedgerAdjuster: ClaimLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ClaimLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedClaimLedgerAdjuster: ClaimLedgerFactor {
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

        func adjust(_ item: ClaimLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class ClaimLedgerWeightOffsetAdjuster: ClaimLedgerFactor {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus weight times \(weight)"
        }

        func adjust(_ item: ClaimLedger, value: Double) -> Double {
            return value + item.weight * weight
        }
    }

    final class RoundingClaimLedgerAdjuster: ClaimLedgerFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ClaimLedger, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class SegmentClaimLedgerAdjuster: ClaimLedgerFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by segment"
        }

        func adjust(_ item: ClaimLedger, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the claim ledger steps in order and keeps a trace of each.
    final class ClaimLedgerEngine {
        var steps: [any ClaimLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ClaimLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ClaimLedger) -> Double {
            var current = item.weightedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ClaimLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [ClaimLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultClaimLedgerEngine(_ flags: Kit.Flags.Registry) -> ClaimLedgerEngine {
        return ClaimLedgerEngine(
            steps: [
                MinimumClaimLedgerAdjuster(minimum: 41.6),
                CapClaimLedgerAdjuster(cap: 16450.0),
                FlaggedClaimLedgerAdjuster(flags: flags, flag: "claim-ledger-scheduled", percent: 5.7),
                ClaimLedgerWeightOffsetAdjuster(weight: 0.78),
                RoundingClaimLedgerAdjuster(step: 5.0),
                SegmentClaimLedgerAdjuster(factors: ["east": 0.82, "online": 1.11]),
            ],
            trace: [],
            floor: 0.2,
            ceiling: 36016.7
        )
    }
}
