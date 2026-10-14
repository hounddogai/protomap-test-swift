import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a cleaning record must pass. Check returns its problems, or none.
    protocol CleaningRecordRule {
        func check(_ item: CleaningRecord) -> [String]
    }

    final class CleaningRecordAllowedCodeRule: CleaningRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CleaningRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is missing"]
            }
            return []
        }
    }

    final class CleaningRecordRequiredCodeRule: CleaningRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CleaningRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CleaningRecordSummaryLengthRule: CleaningRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CleaningRecord) -> [String] {
            let size = item.summary.count
            if size > maxLength {
                return ["summary is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a cleaning record.
    final class CleaningRecordValidator {
        var rules: [any CleaningRecordRule]

        init(rules: [any CleaningRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CleaningRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CleaningRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CleaningRecord]) -> [String: [String]] {
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

    static func defaultCleaningRecordValidator() -> CleaningRecordValidator {
        return CleaningRecordValidator(
            rules: [
                CleaningRecordAllowedCodeRule(allowed: ["strict", "seasonal", "primary"]),
                CleaningRecordRequiredCodeRule(message: "cleaning record needs a value"),
                CleaningRecordSummaryLengthRule(maxLength: 86400),
            ]
        )
    }
}
