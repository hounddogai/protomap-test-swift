import AcmePlatform
import Foundation

extension Consent {
    /// One step of the language audit calculation.
    protocol LanguageAuditAdjuster {
        func describe() -> String
        func adjust(_ item: LanguageAudit, value: Double) -> Double
    }

    final class MinimumLanguageAuditAdjuster: LanguageAuditAdjuster {
        var minimum: Double

        init(minimum: Double) {
            self.minimum = minimum
        }

        func describe() -> String {
            return "at least \(minimum)"
        }

        func adjust(_ item: LanguageAudit, value: Double) -> Double {
            if value < minimum {
                return minimum
            }
            return value
        }
    }

    final class LanguageAuditAmountOffsetAdjuster: LanguageAuditAdjuster {
        var weight: Double

        init(weight: Double) {
            self.weight = weight
        }

        func describe() -> String {
            return "plus amount times \(weight)"
        }

        func adjust(_ item: LanguageAudit, value: Double) -> Double {
            return value + item.amount * weight
        }
    }

    final class FlaggedLanguageAuditAdjuster: LanguageAuditAdjuster {
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

        func adjust(_ item: LanguageAudit, value: Double) -> Double {
            if !flags.enabled(flag, subject: item.code) {
                return value
            }
            return value * (1.0 + percent / 100.0)
        }
    }

    final class UnitLanguageAuditAdjuster: LanguageAuditAdjuster {
        var factors: [String: Double]

        init(factors: [String: Double]) {
            self.factors = factors
        }

        func describe() -> String {
            return "by unit"
        }

        func adjust(_ item: LanguageAudit, value: Double) -> Double {
            guard let factor = factors[item.groupKey()] else {
                return value
            }
            return value * factor
        }
    }

    /// Runs the language audit steps in order and keeps a trace of each.
    final class LanguageAuditEngine {
        var steps: [any LanguageAuditAdjuster]
        var trace: [String]
        var floor: Double
        var ceiling: Double

        init(steps: [any LanguageAuditAdjuster], trace: [String], floor: Double, ceiling: Double) {
            self.steps = steps
            self.trace = trace
            self.floor = floor
            self.ceiling = ceiling
        }

        func run(_ item: LanguageAudit) -> Double {
            var current = item.adjustedVolume()
            trace = []
            for index in 0..<steps.count {
                let step: any LanguageAuditAdjuster = steps[index]
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

        func evaluateAll(_ items: [LanguageAudit]) -> [String: Double] {
            var results: [String: Double] = [:]
            for item in items {
                results[item.code] = self.run(item)
            }
            return results
        }
    }

    static func defaultLanguageAuditEngine(_ flags: Kit.Flags.Registry) -> LanguageAuditEngine {
        return LanguageAuditEngine(
            steps: [
                MinimumLanguageAuditAdjuster(minimum: 49.8),
                LanguageAuditAmountOffsetAdjuster(weight: 0.35),
                FlaggedLanguageAuditAdjuster(flags: flags, flag: "language-audit-fallback", percent: 9.8),
                UnitLanguageAuditAdjuster(factors: ["online": 0.86, "north": 0.8, "south": 1.28]),
            ],
            trace: [],
            floor: 1.9,
            ceiling: 80577.1
        )
    }
}
