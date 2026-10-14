import AcmePlatform
import Foundation

extension Consent {
    /// One step of the proxy audit calculation.
    protocol ProxyAuditAdjuster {
        func describe() -> String
        func adjust(_ item: ProxyAudit, value: Double) -> Double
    }

    final class PercentProxyAuditAdjuster: ProxyAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ProxyAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedProxyAuditAdjuster: ProxyAuditAdjuster {
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

        func adjust(_ item: ProxyAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class RoundingProxyAuditAdjuster: ProxyAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ProxyAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class CapProxyAuditAdjuster: ProxyAuditAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: ProxyAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    /// Runs the proxy audit steps in order and keeps a trace of each.
    final class ProxyAuditEngine {
        var steps: [any ProxyAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ProxyAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: ProxyAudit) -> Double {
            var current = item.adjustedExposure()
            trace = []
            for index in 0..<steps.count {
                let step: any ProxyAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [ProxyAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultProxyAuditEngine(_ flags: Kit.Flags.Registry) -> ProxyAuditEngine {
        return ProxyAuditEngine(
            steps: [
                PercentProxyAuditAdjuster(percent: 22.0),
                FlaggedProxyAuditAdjuster(flags: flags, flag: "proxy-audit-default", percent: 1.6),
                RoundingProxyAuditAdjuster(step: 0.1),
                CapProxyAuditAdjuster(cap: 4957.0),
            ],
            trace: [],
            floor: 2.2,
            ceiling: 70695.4
        )
    }
}
