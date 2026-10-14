import AcmePlatform
import Foundation

extension RevenueCycle {
    /// A rule a charge entry must pass. Check returns its problems, or none.
    protocol ChargeEntryRule {
        func check(_ item: ChargeEntry) -> [String]
    }

    final class ChargeEntryArchivedGuardRule: ChargeEntryRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: ChargeEntry) -> [String] {
            if item.archived && (item.endsAt > limit) {
                return ["ends at \(item.endsAt) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class ChargeEntryScoreRangeRule: ChargeEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeEntry) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ChargeEntryEndsAtRangeRule: ChargeEntryRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: ChargeEntry) -> [String] {
            let value = item.endsAt
            var problems: [String] = []
            if value < min {
                problems.append("ends at \(value) is below \(min)")
            }
            if value > max {
                problems.append("ends at \(value) is above \(max)")
            }
            return problems
        }
    }

    final class ChargeEntryLabelLengthRule: ChargeEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ChargeEntry) -> [String] {
            let size = item.label.count
            if size > maxLength {
                return ["label is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a charge entry.
    final class ChargeEntryValidator {
        var rules: [any ChargeEntryRule]

        init(rules: [any ChargeEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: ChargeEntry) -> [String] {
            var problems: [String] = []
            for rule in rules {
                let found = rule.check(item)
                if found.count == 0 {
                    continue
                }
                for problem in found {
                    problems.append("\(item.code): \(problem)")
                }
            }
            return problems
        }

        func requireValid(_ item: ChargeEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ChargeEntry]) -> [String: [String]] {
            var report: [String: [String]] = [:]
            for item in items {
                let problems = self.validate(item)
                if problems.count > 0 {
                    report[item.code] = problems
                }
            }
            return report
        }
    }

    static func defaultChargeEntryValidator() -> ChargeEntryValidator {
        return ChargeEntryValidator(
            rules: [
                ChargeEntryArchivedGuardRule(limit: 3600),
                ChargeEntryScoreRangeRule(min: 4.9, max: 3449.4),
                ChargeEntryEndsAtRangeRule(min: 32, max: 86400),
                ChargeEntryLabelLengthRule(maxLength: 32),
            ]
        )
    }
}
