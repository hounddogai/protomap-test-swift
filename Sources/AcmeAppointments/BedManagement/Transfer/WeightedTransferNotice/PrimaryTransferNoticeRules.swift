import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a primary transfer notice must pass. Check returns its problems, or none.
    protocol PrimaryTransferNoticeRule {
        func check(_ item: PrimaryTransferNotice) -> [String]
    }

    final class PrimaryTransferNoticeCodePrefixRule: PrimaryTransferNoticeRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: PrimaryTransferNotice) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class PrimaryTransferNoticeRequiredAllergyRule: PrimaryTransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferNotice) -> [String] {
            if item.allergy.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTransferNoticeRequiredCodeRule: PrimaryTransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferNotice) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTransferNoticeRequiredDescriptionRule: PrimaryTransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferNotice) -> [String] {
            if item.description.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class PrimaryTransferNoticeRequiredTitleRule: PrimaryTransferNoticeRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: PrimaryTransferNotice) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a primary transfer notice.
    final class PrimaryTransferNoticeValidator {
        var rules: [any PrimaryTransferNoticeRule]

        init(rules: [any PrimaryTransferNoticeRule]) {
            self.rules = rules
        }

        func validate(_ item: PrimaryTransferNotice) -> [String] {
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

        func requireValid(_ item: PrimaryTransferNotice) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [PrimaryTransferNotice]) -> [String: [String]] {
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

    static func defaultPrimaryTransferNoticeValidator() -> PrimaryTransferNoticeValidator {
        return PrimaryTransferNoticeValidator(
            rules: [
                PrimaryTransferNoticeCodePrefixRule(prefix: "X"),
                PrimaryTransferNoticeRequiredAllergyRule(message: "primary transfer notice needs an entry"),
                PrimaryTransferNoticeRequiredCodeRule(message: "primary transfer notice needs an entry"),
                PrimaryTransferNoticeRequiredDescriptionRule(message: "primary transfer notice needs this field"),
                PrimaryTransferNoticeRequiredTitleRule(message: "primary transfer notice needs an entry"),
            ]
        )
    }
}
