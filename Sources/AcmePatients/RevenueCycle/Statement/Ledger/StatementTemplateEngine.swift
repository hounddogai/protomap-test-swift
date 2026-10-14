import AcmePlatform
import Foundation

extension RevenueCycle {
    /// One step of the statement template calculation.
    protocol StatementTemplateAdjuster {
        func describe() -> String
        func adjust(_ item: StatementTemplate, value: Double) -> Double
    }

    final class MinimumStatementTemplateAdjuster: StatementTemplateAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: StatementTemplate, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class CapStatementTemplateAdjuster: StatementTemplateAdjuster {
        var cap: Double

        init(cap: Double) {
            self.cap = cap
        }

        func describe() -> String {
            return "cap at \(cap)"
        }

        func adjust(_ item: StatementTemplate, value: Double) -> Double {
            return Swift.min(value, cap)
        }
    }

    final class PercentStatementTemplateAdjuster: StatementTemplateAdjuster {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: StatementTemplate, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class LocaleStatementTemplateAdjuster: StatementTemplateAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by locale"
        }

        func adjust(_ item: StatementTemplate, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class FlaggedStatementTemplateAdjuster: StatementTemplateAdjuster {
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

        func adjust(_ item: StatementTemplate, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    /// Runs the statement template steps in order and keeps a trace of each.
    final class StatementTemplateEngine {
        var steps: [any StatementTemplateAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any StatementTemplateAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func compute(_ item: StatementTemplate) -> Double {
            var current = item.weightedVolume()
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

        func evaluateAll(_ items: [StatementTemplate]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.compute(item)
            }
            return results
        }
    }

    static func defaultStatementTemplateEngine(_ flags: Kit.Flags.Registry) -> StatementTemplateEngine {
        return StatementTemplateEngine(
            steps: [
                MinimumStatementTemplateAdjuster(minimum: 36.5),
                CapStatementTemplateAdjuster(cap: 34732.0),
                PercentStatementTemplateAdjuster(percent: 8.5),
                LocaleStatementTemplateAdjuster(factors: ["east": 1.3, "west": 0.91, "south": 1.27]),
                FlaggedStatementTemplateAdjuster(flags: flags, flag: "statement-template-global", percent: 8.3),
            ],
            trace: [],
            floor: 3.4,
            ceiling: 52718.1
        )
    }
}
