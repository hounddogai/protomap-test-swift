import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a interaction notice must pass. Check returns its problems, or none.
    protocol InteractionNoticeRule {
        func check(_ item: InteractionNotice) -> [String]
    }

    final class InteractionNoticeRequiredFacilityRule: InteractionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionNotice) -> [String] {
            if item.facility.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class InteractionNoticeFacilityLengthRule: InteractionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionNotice) -> [String] {
            let size = item.facility.count
            if size > maxLength {
                return ["facility is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionNoticeCodePrefixRule: InteractionNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: InteractionNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class InteractionNoticeTimezoneLengthRule: InteractionNoticeRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: InteractionNotice) -> [String] {
            let size = item.timezone.count
            if size > maxLength {
                return ["timezone is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class InteractionNoticeRequiredLabelRule: InteractionNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: InteractionNotice) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a interaction notice.
    final class InteractionNoticeValidator {
        var rules: [any InteractionNoticeRule]

        init(rules: [any InteractionNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: InteractionNotice) -> [String] {
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

        func requireValid(_ item: InteractionNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [InteractionNotice]) -> [String: [String]] {
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

    static func defaultInteractionNoticeValidator() -> InteractionNoticeValidator {
        return InteractionNoticeValidator(
            rules: [
                InteractionNoticeRequiredFacilityRule(message: "interaction notice needs an entry"),
                InteractionNoticeFacilityLengthRule(maxLength: 255),
                InteractionNoticeCodePrefixRule(prefix: "REF"),
                InteractionNoticeTimezoneLengthRule(maxLength: 255),
                InteractionNoticeRequiredLabelRule(message: "interaction notice needs an entry"),
            ]
        )
    }
}
