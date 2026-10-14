import AcmePlatform
import Foundation

extension Labs {
    /// A rule a courier notice must pass. Check returns its problems, or none.
    protocol CourierNoticeRule {
        func check(_ item: CourierNotice) -> [String]
    }

    final class CourierNoticeRequiredPhoneRule: CourierNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierNotice) -> [String] {
            if item.phone.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierNoticeRequiredCodeRule: CourierNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CourierNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CourierNoticeCodePrefixRule: CourierNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CourierNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class CourierNoticeEncounterIDLengthRule: CourierNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CourierNotice) -> [String] {
            let size = item.encounterID.count
            if size > maxLength {
                return ["encounter id is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a courier notice.
    final class CourierNoticeValidator {
        var rules: [any CourierNoticeRule]

        init(rules: [any CourierNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: CourierNotice) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: CourierNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CourierNotice]) -> [String: [String]] {
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

    static func defaultCourierNoticeValidator() -> CourierNoticeValidator {
        return CourierNoticeValidator(
            rules: [
                CourierNoticeRequiredPhoneRule(message: "courier notice needs this field"),
                CourierNoticeRequiredCodeRule(message: "courier notice needs an entry"),
                CourierNoticeCodePrefixRule(prefix: "ACM"),
                CourierNoticeEncounterIDLengthRule(maxLength: 16),
            ]
        )
    }
}
