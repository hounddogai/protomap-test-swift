import AcmePlatform
import Foundation

extension Labs {
    /// A rule a capped reference range record must pass. Check returns its problems, or none.
    protocol CappedReferenceRangeRecordRule {
        func check(_ item: CappedReferenceRangeRecord) -> [String]
    }

    final class CappedReferenceRangeRecordAllowedContactEmailRule: CappedReferenceRangeRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CappedReferenceRangeRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.contactEmail)) {
                return ["contact email \(item.contactEmail) is duplicated"]
            }
            return []
        }
    }

    final class CappedReferenceRangeRecordCodeLengthRule: CappedReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferenceRangeRecord) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeRecordContactEmailLengthRule: CappedReferenceRangeRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedReferenceRangeRecord) -> [String] {
            let size = item.contactEmail.count
            if size > maxLength {
                return ["contact email is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedReferenceRangeRecordRequiredTitleRule: CappedReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferenceRangeRecord) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedReferenceRangeRecordRequiredContactEmailRule: CappedReferenceRangeRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedReferenceRangeRecord) -> [String] {
            if item.contactEmail.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a capped reference range record.
    final class CappedReferenceRangeRecordValidator {
        var rules: [any CappedReferenceRangeRecordRule]

        init(rules: [any CappedReferenceRangeRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedReferenceRangeRecord) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CappedReferenceRangeRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedReferenceRangeRecord]) -> [String: [String]] {
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

    static func defaultCappedReferenceRangeRecordValidator() -> CappedReferenceRangeRecordValidator {
        return CappedReferenceRangeRecordValidator(
            rules: [
                CappedReferenceRangeRecordAllowedContactEmailRule(allowed: ["capped", "fallback"]),
                CappedReferenceRangeRecordCodeLengthRule(maxLength: 120),
                CappedReferenceRangeRecordContactEmailLengthRule(maxLength: 1000),
                CappedReferenceRangeRecordRequiredTitleRule(message: "capped reference range record needs a value"),
                CappedReferenceRangeRecordRequiredContactEmailRule(
                    message: "capped reference range record needs this field"
                ),
            ]
        )
    }
}
