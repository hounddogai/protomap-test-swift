import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the care protocol ledger calculation.
    protocol CareProtocolLedgerAdjuster {
        func describe() -> String
        func adjust(_ item: CareProtocolLedger, value: Double) -> Double
    }

    final class CapCareProtocolLedgerAdjuster: CareProtocolLedgerAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: CareProtocolLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class FlaggedCareProtocolLedgerAdjuster: CareProtocolLedgerAdjuster {
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

        func adjust(_ item: CareProtocolLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CareProtocolLedgerCreatedAtOffsetAdjuster: CareProtocolLedgerAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus created at times \(weight)"
        }

        func adjust(_ item: CareProtocolLedger, value: Double) -> Double {
            return value + Double(item.createdAt) * weight
        }
    }

    final class PercentCareProtocolLedgerAdjuster: CareProtocolLedgerAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: CareProtocolLedger, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the care protocol ledger steps in order and keeps a trace of each.
    final class CareProtocolLedgerEngine {
        var steps: [any CareProtocolLedgerAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any CareProtocolLedgerAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: CareProtocolLedger) -> Double {
            var current = item.netValue()
            trace = []
            for index in 0..<steps.count {
                let step: any CareProtocolLedgerAdjuster = steps[index]
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

        func evaluateAll(_ items: [CareProtocolLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultCareProtocolLedgerEngine(_ flags: Kit.Flags.Registry) -> CareProtocolLedgerEngine {
        return CareProtocolLedgerEngine(
            steps: [
                CapCareProtocolLedgerAdjuster(cap: 14461.0),
                FlaggedCareProtocolLedgerAdjuster(flags: flags, flag: "care-protocol-ledger-strict", percent: -2.3),
                CareProtocolLedgerCreatedAtOffsetAdjuster(weight: 1.72),
                PercentCareProtocolLedgerAdjuster(percent: -11.1),
            ],
            trace: [],
            floor: 3.7,
            ceiling: 67605.0
        )
    }
}
