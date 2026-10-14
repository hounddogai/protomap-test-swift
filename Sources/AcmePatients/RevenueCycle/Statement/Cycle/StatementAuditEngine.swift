import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement audit calculation.
    protocol StatementAuditStep {
        func describe() -> String
        func adjust(_ item: StatementAudit, value: Double) -> Double
    }

    final class CapStatementAuditAdjuster: StatementAuditStep {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementAudit, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class RegionStatementAuditAdjuster: StatementAuditStep {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by region"
        }

        func adjust(_ item: StatementAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class StatementAuditScoreOffsetAdjuster: StatementAuditStep {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus score times \(weight)"
        }

        func adjust(_ item: StatementAudit, value: Double) -> Double {
            return value + item.score * weight
        }
    }

    final class FlaggedStatementAuditAdjuster: StatementAuditStep {
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

        func adjust(_ item: StatementAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TieredStatementAuditAdjuster: StatementAuditStep {
        var bounds: [Double]
        var rates: [Double]

        init(bounds: [Double], rates: [Double]) {
            self.bounds = bounds
            self.rates = rates
        }

        func describe() -> String {
            return "\(bounds.count) tiers"
        }

        func adjust(_ item: StatementAudit, value: Double) -> Double {
            for index in 0..<bounds.count {
                if value <= bounds[index] && (index < rates.count) {
                    return value * rates[index]
                }
            }
            return value
        }
    }

    final class PercentStatementAuditAdjuster: StatementAuditStep {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement audit steps in order and keeps a trace of each.
    final class StatementAuditEngine {
        var steps: [any StatementAuditStep]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementAuditStep], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StatementAudit) -> Double {
            var current = item.effectiveLoad()
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

        func evaluateAll(_ items: [StatementAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStatementAuditEngine(_ flags: Kit.Flags.Registry) -> StatementAuditEngine {
        return StatementAuditEngine(
            steps: [
                CapStatementAuditAdjuster(cap: 12390.0),
                RegionStatementAuditAdjuster(factors: ["retail": 1.17, "online": 0.98, "central": 1.34]),
                StatementAuditScoreOffsetAdjuster(weight: 1.83),
                FlaggedStatementAuditAdjuster(flags: flags, flag: "statement-audit-regional", percent: -2.3),
                TieredStatementAuditAdjuster(
                    bounds: [3132.0, 3443.0, 6855.0, 8499.0],
                    rates: [1.07, 0.84, 0.95, 1.04]
                ),
                PercentStatementAuditAdjuster(percent: 9.6),
            ],
            trace: [],
            floor: 3.0,
            ceiling: 69951.5
        )
    }
}
