import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a care protocol notice must pass. Check returns its problems, or none.
    protocol CareProtocolNoticeRule {
        func check(_ item: CareProtocolNotice) -> [String]
    }

    final class CareProtocolNoticeRequiredRegionRule: CareProtocolNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            if item.region.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CareProtocolNoticeRequiredTitleRule: CareProtocolNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
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

    final class CareProtocolNoticeRegionLengthRule: CareProtocolNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CareProtocolNotice) -> [String] {
            let size = item.region.count
            if size > maxLength {
                return ["region is \(size) characters, more than \(maxLength)"]
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
                for problem in rule.check(item) {
                    problems.append(problem)
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
                CareProtocolNoticeRequiredRegionRule(message: "care protocol notice needs this field"),
                CareProtocolNoticeRequiredTitleRule(message: "care protocol notice needs an entry"),
                CareProtocolNoticeTitleLengthRule(maxLength: 255),
                CareProtocolNoticeCodeLengthRule(maxLength: 120),
                CareProtocolNoticeRegionLengthRule(maxLength: 16),
            ]
        )
    }
}
