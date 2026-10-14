import AcmePlatform
import Foundation

extension CareManagement {
    /// One step of the default outreach audit calculation.
    protocol DefaultOutreachAuditAdjuster {
        func describe() -> String
        func adjust(_ item: DefaultOutreachAudit, value: Double) -> Double
    }

    final class RegionDefaultOutreachAuditAdjuster: DefaultOutreachAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: DefaultOutreachAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class MinimumDefaultOutreachAuditAdjuster: DefaultOutreachAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: DefaultOutreachAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class FlaggedDefaultOutreachAuditAdjuster: DefaultOutreachAuditAdjuster {
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

        func adjust(_ item: DefaultOutreachAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the default outreach audit steps in order and keeps a trace of each.
    final class DefaultOutreachAuditEngine {
        var steps: [any DefaultOutreachAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any DefaultOutreachAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: DefaultOutreachAudit) -> Double {
            var current = item.measuredValue()
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

        func evaluateAll(_ items: [DefaultOutreachAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultDefaultOutreachAuditEngine(_ flags: Kit.Flags.Registry) -> DefaultOutreachAuditEngine {
        return DefaultOutreachAuditEngine(
            steps: [
                RegionDefaultOutreachAuditAdjuster(factors: ["west": 1.2, "online": 1.02, "central": 1.27]),
                MinimumDefaultOutreachAuditAdjuster(minimum: 16.6),
                FlaggedDefaultOutreachAuditAdjuster(
                    flags: flags,
                    flag: "default-outreach-audit-legacy",
                    percent: -7.5
                ),
            ],
            trace: [],
            floor: 0.0,
            ceiling: 98552.9
        )
    }
}
