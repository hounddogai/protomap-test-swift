import AcmePlatform
import Foundation

extension Referrals {
    /// A rule a follow up mapping must pass. Check returns its problems, or none.
    protocol FollowUpMappingRule {
        func check(_ item: FollowUpMapping) -> [String]
    }

    final class FollowUpMappingRequiredDiagnosisCodeRule: FollowUpMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpMapping) -> [String] {
            if item.diagnosisCode.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class FollowUpMappingCodePrefixRule: FollowUpMappingRule {
        var prefix: String

        init(prefix: String) {
            self.prefix = prefix
        }

        func check(_ item: FollowUpMapping) -> [String] {
            if !item.code.uppercased().hasPrefix(prefix.uppercased()) {
                return ["code must start with \(prefix)"]
            }
            return []
        }
    }

    final class FollowUpMappingRequiredTitleRule: FollowUpMappingRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: FollowUpMapping) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    /// Runs every rule of a follow up mapping.
    final class FollowUpMappingValidator {
        var rules: [any FollowUpMappingRule]

        init(rules: [any FollowUpMappingRule]) {
            self.rules = rules
        }

        func validate(_ item: FollowUpMapping) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: FollowUpMapping) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [FollowUpMapping]) -> [String: [String]] {
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

    static func defaultFollowUpMappingValidator() -> FollowUpMappingValidator {
        return FollowUpMappingValidator(
            rules: [
                FollowUpMappingRequiredDiagnosisCodeRule(message: "follow up mapping needs a value"),
                FollowUpMappingCodePrefixRule(prefix: "ACM"),
                FollowUpMappingRequiredTitleRule(message: "follow up mapping needs a value"),
            ]
        )
    }
}
