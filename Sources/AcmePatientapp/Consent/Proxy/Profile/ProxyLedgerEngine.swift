import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy ledger calculation.
    protocol ProxyLedgerStep {
        func describe() -> String
        func adjust(_ item: ProxyLedger, value: Double) -> Double
    }

    final class FlaggedProxyLedgerAdjuster: ProxyLedgerStep {
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

        func adjust(_ item: ProxyLedger, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class CapProxyLedgerAdjuster: ProxyLedgerStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyLedger, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class MinimumProxyLedgerAdjuster: ProxyLedgerStep {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ProxyLedger, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the proxy ledger steps in order and keeps a trace of each.
    final class ProxyLedgerEngine {
        var steps: [any ProxyLedgerStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyLedgerStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: ProxyLedger) -> Double {
            var current = item.measuredValue()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyLedgerStep = steps[index]
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

        func evaluateAll(_ items: [ProxyLedger]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultProxyLedgerEngine(_ flags: Kit.Flags.Registry) -> ProxyLedgerEngine {
        return ProxyLedgerEngine(
            steps: [
                FlaggedProxyLedgerAdjuster(flags: flags, flag: "proxy-ledger-capped", percent: -2.7),
                CapProxyLedgerAdjuster(cap: 25368.0),
                MinimumProxyLedgerAdjuster(minimum: 34.1),
            ],
            trace: [],
            floor: 3.5,
            ceiling: 7399.0
        )
    }
}
