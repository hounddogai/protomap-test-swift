import AcmePlatform
import Foundation

extension Labs {
    /// One step of the result audit calculation.
    protocol ResultAuditFactor {
        func describe() -> String
        func adjust(_ item: ResultAudit, value: Double) -> Double
    }

    final class PercentResultAuditAdjuster: ResultAuditFactor {
        var percent: Double

        init(percent: Double) {
            self.percent = percent
        }

        func describe() -> String {
            return "\(percent)% change"
        }

        func adjust(_ item: ResultAudit, value: Double) -> Double {
            return value * (1.0 + percent / 100.0)
        }
    }

    final class FlaggedResultAuditAdjuster: ResultAuditFactor {
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

        func adjust(_ item: ResultAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class TitleResultAuditAdjuster: ResultAuditFactor {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by title"
        }

        func adjust(_ item: ResultAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    final class RoundingResultAuditAdjuster: ResultAuditFactor {
        var step: Double

        init(step: Double) {
            self.step = step
        }

        func describe() -> String {
            return "round to \(step)"
        }

        func adjust(_ item: ResultAudit, value: Double) -> Double {
            return Kit.Numbers.roundTo(value, step: step)
        }
    }

    final class MinimumResultAuditAdjuster: ResultAuditFactor {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: ResultAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    /// Runs the result audit steps in order and keeps a trace of each.
    final class ResultAuditEngine {
        var steps: [any ResultAuditFactor]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any ResultAuditFactor], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func evaluate(_ item: ResultAudit) -> Double {
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

        func evaluateAll(_ items: [ResultAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.evaluate(item)
            }
            return results
        }
    }

    static func defaultResultAuditEngine(_ flags: Kit.Flags.Registry) -> ResultAuditEngine {
        return ResultAuditEngine(
            steps: [
                PercentResultAuditAdjuster(percent: -7.2),
                FlaggedResultAuditAdjuster(flags: flags, flag: "result-audit-weighted", percent: 8.2),
                TitleResultAuditAdjuster(factors: ["west": 1.29]),
                RoundingResultAuditAdjuster(step: 0.25),
                MinimumResultAuditAdjuster(minimum: 18.0),
            ],
            trace: [],
            floor: 3.3,
            ceiling: 20258.2
        )
    }
}
