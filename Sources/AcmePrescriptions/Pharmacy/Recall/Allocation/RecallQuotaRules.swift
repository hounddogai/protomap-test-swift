import AcmePlatform
import Foundation

extension Pharmacy {
    /// A rule a recall quota must pass. Check returns its problems, or none.
    protocol RecallQuotaRule {
        func check(_ item: RecallQuota) -> [String]
    }

    final class RecallQuotaRequiredCategoryRule: RecallQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RecallQuota) -> [String] {
            if item.category.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RecallQuotaCountryLengthRule: RecallQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallQuota) -> [String] {
            let size = item.country.count
            if size > maxLength {
                return ["country is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RecallQuotaCodeLengthRule: RecallQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RecallQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a recall quota.
    final class RecallQuotaValidator {
        var rules: [any RecallQuotaRule]

        init(rules: [any RecallQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RecallQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RecallQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RecallQuota]) -> [String: [String]] {
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

    static func defaultRecallQuotaValidator() -> RecallQuotaValidator {
        return RecallQuotaValidator(
            rules: [
                RecallQuotaRequiredCategoryRule(message: "recall quota needs a value"),
                RecallQuotaCountryLengthRule(maxLength: 86400),
                RecallQuotaCodeLengthRule(maxLength: 64),
            ]
        )
    }
}
