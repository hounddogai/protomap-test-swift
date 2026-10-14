import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a capped task entry must pass. Check returns its problems, or none.
    protocol CappedTaskEntryRule {
        func check(_ item: CappedTaskEntry) -> [String]
    }

    final class CappedTaskEntryRequiredTitleRule: CappedTaskEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedTaskEntry) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedTaskEntryDiscountRangeRule: CappedTaskEntryRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CappedTaskEntry) -> [String] {
            let value = item.discount
            var problems: [String] = []
            if value < min {
                problems.append("discount \(value) is below \(min)")
            }
            if value > max {
                problems.append("discount \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CappedTaskEntryRequiredCodeRule: CappedTaskEntryRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedTaskEntry) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedTaskEntryTitleLengthRule: CappedTaskEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedTaskEntry) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedTaskEntryCodeLengthRule: CappedTaskEntryRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedTaskEntry) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped task entry.
    final class CappedTaskEntryValidator {
        var rules: [any CappedTaskEntryRule]

        init(rules: [any CappedTaskEntryRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedTaskEntry) -> [String] {
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

        func requireValid(_ item: CappedTaskEntry) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedTaskEntry]) -> [String: [String]] {
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

    static func defaultCappedTaskEntryValidator() -> CappedTaskEntryValidator {
        return CappedTaskEntryValidator(
            rules: [
                CappedTaskEntryRequiredTitleRule(message: "capped task entry needs an entry"),
                CappedTaskEntryDiscountRangeRule(min: 9.9, max: 2179.6),
                CappedTaskEntryRequiredCodeRule(message: "capped task entry needs this field"),
                CappedTaskEntryTitleLengthRule(maxLength: 80),
                CappedTaskEntryCodeLengthRule(maxLength: 16),
            ]
        )
    }
}
