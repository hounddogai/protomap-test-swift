import AcmePlatform
import Foundation

extension Labs {
    /// A rule a rolling panel quota must pass. Check returns its problems, or none.
    protocol RollingPanelQuotaRule {
        func check(_ item: RollingPanelQuota) -> [String]
    }

    final class RollingPanelQuotaAllergyLengthRule: RollingPanelQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelQuota) -> [String] {
            let size = item.allergy.count
            if size > maxLength {
                return ["allergy is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPanelQuotaCodeLengthRule: RollingPanelQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelQuota) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPanelQuotaTitleLengthRule: RollingPanelQuotaRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RollingPanelQuota) -> [String] {
            let size = item.title.count
            if size > maxLength {
                return ["title is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RollingPanelQuotaRequiredSpecialtyRule: RollingPanelQuotaRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RollingPanelQuota) -> [String] {
            if item.specialty.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a rolling panel quota.
    final class RollingPanelQuotaValidator {
        var rules: [any RollingPanelQuotaRule]

        init(rules: [any RollingPanelQuotaRule]) {
            self.rules = rules
        }

        func validate(_ item: RollingPanelQuota) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RollingPanelQuota) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RollingPanelQuota]) -> [String: [String]] {
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

    static func defaultRollingPanelQuotaValidator() -> RollingPanelQuotaValidator {
        return RollingPanelQuotaValidator(
            rules: [
                RollingPanelQuotaAllergyLengthRule(maxLength: 32),
                RollingPanelQuotaCodeLengthRule(maxLength: 16),
                RollingPanelQuotaTitleLengthRule(maxLength: 255),
                RollingPanelQuotaRequiredSpecialtyRule(message: "rolling panel quota needs an entry"),
            ]
        )
    }
}
