import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall record must pass. Check returns its problems, or none.
    protocol RecallRecordRule {
        func check(_ item: RecallRecord) -> [String]
    }

    final class RecallRecordTitleLengthRule: RecallRecordRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallRecord) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallRecordApprovedGuardRule: RecallRecordRule {
        var limit: Double

        init(limit: Double) {
            self.limit = limit
        }

        func check(_ item: RecallRecord) -> [String] {
            if item.approved && (item.copay > limit) {
                return ["copay \(item.copay) exceeds \(limit) while approved"]
            }
            return []
        }
    }

    final class RecallRecordAllowedCodeRule: RecallRecordRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: RecallRecord) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class RecallRecordRequiredCodeRule: RecallRecordRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallRecord) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a recall record.
    final class RecallRecordValidator {
        var rules: [any RecallRecordRule]

        init(rules: [any RecallRecordRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallRecord) -> [String] {
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

        func requireValid(_ item: RecallRecord) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallRecord]) -> [String: [String]] {
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

    static func defaultRecallRecordValidator() -> RecallRecordValidator {
        return RecallRecordValidator(
            rules: [
                RecallRecordTitleLengthRule(maxLength: 32),
                RecallRecordApprovedGuardRule(limit: 4.6),
                RecallRecordAllowedCodeRule(allowed: ["global"]),
                RecallRecordRequiredCodeRule(message: "recall record needs an entry"),
            ]
        )
    }
}
