import AcmePlatform
import Foundation

extension ClinicalOps {
    /// A rule a care protocol notice must pass. Check returns its problems, or none.
    protocol CareProtocolNoticeRule {
        func check(_ item: CareProtocolNotice) -> [String]
    }

    final class CareProtocolNoticeCodeLengthRule: CareProtocolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolNoticeSequenceRangeRule: CareProtocolNoticeRule {
        var min: Int
        var max: Int

        init(min: Int, max: Int) {
            self.min = min
            self.max = max
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            let value = item.sequence
            if value < min || value > max {
                return ["sequence \(value) is outside \(min) to \(max)"]
            }
            return []
        }
    }

    final class CareProtocolNoticeCodePrefixRule: CareProtocolNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CareProtocolNoticeTitleLengthRule: CareProtocolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CareProtocolNoticeClinicianIDLengthRule: CareProtocolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            let size = item.clinicianID.count
            if size > maxLength {
                return ["clinician id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a care protocol notice.
    final class CareProtocolNoticeValidator {
        var rules: [any CareProtocolNoticeRule]

        init(rules: [any CareProtocolNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CareProtocolNotice) -> [String] {
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

        func requireValid(_ item: CareProtocolNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CareProtocolNotice]) -> [String: [String]] {
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

    static func defaultCareProtocolNoticeValidator() -> CareProtocolNoticeValidator {
        return CareProtocolNoticeValidator(
            rules: [
                CareProtocolNoticeCodeLengthRule(maxLength: 120),
                CareProtocolNoticeSequenceRangeRule(min: 16, max: 32),
                CareProtocolNoticeCodePrefixRule(prefix: "Q"),
                CareProtocolNoticeTitleLengthRule(maxLength: 86400),
                CareProtocolNoticeClinicianIDLengthRule(maxLength: 16),
            ]
        )
    }
}
