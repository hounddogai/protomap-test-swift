import AcmePlatform
import Foundation

extension BedManagement {
    /// A rule a capped cleaning agreement must pass. Check returns its problems, or none.
    protocol CappedCleaningAgreementRule {
        func check(_ item: CappedCleaningAgreement) -> [String]
    }

    final class CappedCleaningAgreementArchivedGuardRule: CappedCleaningAgreementRule {
        var limit: Int

        init(limit: Int) {
            self.limit = limit
        }

        func check(_ item: CappedCleaningAgreement) -> [String] {
            if item.archived && (item.batchSize > limit) {
                return ["batch size \(item.batchSize) exceeds \(limit) while archived"]
            }
            return []
        }
    }

    final class CappedCleaningAgreementRequiredCodeRule: CappedCleaningAgreementRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: CappedCleaningAgreement) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class CappedCleaningAgreementCodeLengthRule: CappedCleaningAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCleaningAgreement) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCleaningAgreementTitleLengthRule: CappedCleaningAgreementRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CappedCleaningAgreement) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CappedCleaningAgreementCodePrefixRule: CappedCleaningAgreementRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: CappedCleaningAgreement) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    /// Runs every rule of a capped cleaning agreement.
    final class CappedCleaningAgreementValidator {
        var rules: [any CappedCleaningAgreementRule]

        init(rules: [any CappedCleaningAgreementRule]) {
            self.rules = rules
        }

        func validate(_ item: CappedCleaningAgreement) -> [String] {
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

        func requireValid(_ item: CappedCleaningAgreement) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CappedCleaningAgreement]) -> [String: [String]] {
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

    static func defaultCappedCleaningAgreementValidator() -> CappedCleaningAgreementValidator {
        return CappedCleaningAgreementValidator(
            rules: [
                CappedCleaningAgreementArchivedGuardRule(limit: 64),
                CappedCleaningAgreementRequiredCodeRule(message: "capped cleaning agreement needs a value"),
                CappedCleaningAgreementCodeLengthRule(maxLength: 86400),
                CappedCleaningAgreementTitleLengthRule(maxLength: 64),
                CappedCleaningAgreementCodePrefixRule(prefix: "ACM"),
            ]
        )
    }
}
