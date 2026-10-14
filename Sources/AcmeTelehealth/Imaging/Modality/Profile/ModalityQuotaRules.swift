import AcmePlatform
import Foundation

extension Imaging {
    /// A rule a modality quota must pass. Check returns its problems, or none.
    protocol ModalityQuotaRule {
        func check(_ item: ModalityQuota) -> [String]
    }

    final class ModalityQuotaRequiredCodeRule: ModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityQuota) -> [String] {
            if item.code.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityQuotaRequiredWardRule: ModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityQuota) -> [String] {
            if item.ward.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class ModalityQuotaRequiredTitleRule: ModalityQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: ModalityQuota) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a modality quota.
    final class ModalityQuotaValidator {
        var rules: [any ModalityQuotaRule]

        init(rules: [any ModalityQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: ModalityQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: ModalityQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [ModalityQuota]) -> [String: [String]] {
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

    static func defaultModalityQuotaValidator() -> ModalityQuotaValidator {
        return ModalityQuotaValidator(
            rules: [
                ModalityQuotaRequiredCodeRule(message: "modality quota needs a value"),
                ModalityQuotaRequiredWardRule(message: "modality quota needs an entry"),
                ModalityQuotaRequiredTitleRule(message: "modality quota needs a value"),
            ]
        )
    }
}
