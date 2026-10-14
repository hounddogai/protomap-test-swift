import AcmePlatform
import Foundation

extension Imaging {
    /// One step of the read audit calculation.
    protocol ReadAuditAdjuster {
        func describe() -> String
        func adjust(_ item: ReadAudit, value: Double) -> Double
    }

    final class RoundingReadAuditAdjuster: ReadAuditAdjuster {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ReadAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class FlaggedReadAuditAdjuster: ReadAuditAdjuster {
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

        func adjust(_ item: ReadAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class PercentReadAuditAdjuster: ReadAuditAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ReadAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the read audit steps in order and keeps a trace of each.
    final class ReadAuditEngine {
        var steps: [any ReadAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ReadAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func price(_ item: ReadAudit) -> Double {
            var current = item.netVolume()
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

        func evaluateAll(_ items: [ReadAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.price(item)
            }
            return results
        }
    }

    static func defaultReadAuditEngine(_ flags: Kit.Flags.Registry) -> ReadAuditEngine {
        return ReadAuditEngine(
            steps: [
                RoundingReadAuditAdjuster(step: 0.25),
                FlaggedReadAuditAdjuster(flags: flags, flag: "read-audit-default", percent: -6.3),
                PercentReadAuditAdjuster(percent: -11.1),
            ],
            trace: [],
            floor: 1.5,
            ceiling: 95309.6
        )
    }
}
