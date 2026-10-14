import AcmePlatform
import Foundation

extension Staffing {
    /// One step of the pending credential ledger calculation.
    protocol PendingCredentialLedgerFactor {
        func describe() -> String
        func adjust(_ item: PendingCredentialLedger, value: Double) -> Double
    }

    final class CapPendingCredentialLedgerAdjuster: PendingCredentialLedgerFactor {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: PendingCredentialLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedPendingCredentialLedgerAdjuster: PendingCredentialLedgerFactor {
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

        func adjust(_ item: PendingCredentialLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredPendingCredentialLedgerAdjuster: PendingCredentialLedgerFactor {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: PendingCredentialLedger, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentPendingCredentialLedgerAdjuster: PendingCredentialLedgerFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: PendingCredentialLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the pending credential ledger steps in order and keeps a trace of each.
    final class PendingCredentialLedgerEngine {
        var steps: [any PendingCredentialLedgerFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any PendingCredentialLedgerFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: PendingCredentialLedger) -> Double {
            var current = item.projectedTotal()
            trace = []
            for index in 0..<steps.count {
                let step: any PendingCredentialLedgerFactor = steps[index]
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

        func evaluateAll(_ items: [PendingCredentialLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultPendingCredentialLedgerEngine(_ flags: Kit.Flags.Registry) -> PendingCredentialLedgerEngine {
        return PendingCredentialLedgerEngine(
            steps: [
                CapPendingCredentialLedgerAdjuster(cap: 24571.0),
                FlaggedPendingCredentialLedgerAdjuster(
                    flags: flags,
                    flag: "pending-credential-ledger-batched",
                    percent: 6.0
                ),
                TieredPendingCredentialLedgerAdjuster(bounds: [2275.0, 2674.0, 7977.0], rates: [1.14, 0.83, 1.11]),
                PercentPendingCredentialLedgerAdjuster(percent: 15.4),
            ],
            trace: [],
            floor: 2.3,
            ceiling: 99565.1
        )
    }
}
