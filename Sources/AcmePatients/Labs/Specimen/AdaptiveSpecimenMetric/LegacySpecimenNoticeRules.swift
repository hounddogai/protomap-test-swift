import AcmePlatform
import Foundation

extension Labs {
    /// A rule a legacy specimen notice must pass. Check returns its problems, or none.
    protocol LegacySpecimenNoticeRule {
        func check(_ item: LegacySpecimenNotice) -> [String]
    }

    final class LegacySpecimenNoticeCodeLengthRule: LegacySpecimenNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySpecimenNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySpecimenNoticeDiagnosisCodeLengthRule: LegacySpecimenNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: LegacySpecimenNotice) -> [String] {
            let size = item.diagnosisCode.count
            if size > maxLength {
                return ["diagnosis code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class LegacySpecimenNoticeRequiredTitleRule: LegacySpecimenNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: LegacySpecimenNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a legacy specimen notice.
    final class LegacySpecimenNoticeValidator {
        var rules: [any LegacySpecimenNoticeRule]

        init(rules: [any LegacySpecimenNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: LegacySpecimenNotice) -> [String] {
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

        func requireValid(_ item: LegacySpecimenNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [LegacySpecimenNotice]) -> [String: [String]] {
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

    static func defaultLegacySpecimenNoticeValidator() -> LegacySpecimenNoticeValidator {
        return LegacySpecimenNoticeValidator(
            rules: [
                LegacySpecimenNoticeCodeLengthRule(maxLength: 32),
                LegacySpecimenNoticeDiagnosisCodeLengthRule(maxLength: 32),
                LegacySpecimenNoticeRequiredTitleRule(message: "legacy specimen notice needs this field"),
            ]
        )
    }
}
