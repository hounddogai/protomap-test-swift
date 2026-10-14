import AcmePlatform
import Foundation

extension CareManagement {
    /// A rule a manual outreach record must pass. Check returns its problems, or none.
    protocol ManualOutreachRecordRule {
        func check(_ item: ManualOutreachRecord) -> [String]
    }

    final class ManualOutreachRecordScoreRangeRule: ManualOutreachRecordRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: ManualOutreachRecord) -> [String] {
            let value = item.score
            if value < min || value > max {
                return ["score \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class ManualOutreachRecordCodePrefixRule: ManualOutreachRecordRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: ManualOutreachRecord) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class ManualOutreachRecordCategoryLengthRule: ManualOutreachRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachRecord) -> [String] {
            let size = item.category.count
            if size > maxLength {
                return ["category is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class ManualOutreachRecordAllowedNameRule: ManualOutreachRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: ManualOutreachRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.name)) {
                return ["name \(item.name) is out of range"]
            }
            return []
        }
    }

    final class ManualOutreachRecordNameLengthRule: ManualOutreachRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: ManualOutreachRecord) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a manual outreach record.
    final class ManualOutreachRecordValidator {
        var rules: [any ManualOutreachRecordRule]

        init(rules: [any ManualOutreachRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: ManualOutreachRecord) -> [String] {
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

        func requireValid(_ item: ManualOutreachRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ManualOutreachRecord]) -> [String: [String]] {
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

    static func defaultManualOutreachRecordValidator() -> ManualOutreachRecordValidator {
        return ManualOutreachRecordValidator(
            rules: [
                ManualOutreachRecordScoreRangeRule(min: 1.1, max: 3092.6),
                ManualOutreachRecordCodePrefixRule(prefix: "X"),
                ManualOutreachRecordCategoryLengthRule(maxLength: 64),
                ManualOutreachRecordAllowedNameRule(allowed: ["rolling", "scheduled"]),
                ManualOutreachRecordNameLengthRule(maxLength: 80),
            ]
        )
    }
}
