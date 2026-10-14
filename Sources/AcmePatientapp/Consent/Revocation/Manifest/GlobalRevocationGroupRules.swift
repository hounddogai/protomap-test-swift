import AcmePlatform
import Foundation

extension Consent {
    /// A rule a global revocation group must pass. Check returns its problems, or none.
    protocol GlobalRevocationGroupRule {
        func check(_ item: GlobalRevocationGroup) -> [String]
    }

    final class GlobalRevocationGroupRequiredBedRule: GlobalRevocationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRevocationGroup) -> [String] {
            if item.bed.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRevocationGroupRequiredTitleRule: GlobalRevocationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: GlobalRevocationGroup) -> [String] {
            if item.title.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class GlobalRevocationGroupAllowedTitleRule: GlobalRevocationGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: GlobalRevocationGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.title)) {
                return ["title \(item.title) is expired"]
            }
            return []
        }
    }

    final class GlobalRevocationGroupCodeLengthRule: GlobalRevocationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: GlobalRevocationGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a global revocation group.
    final class GlobalRevocationGroupValidator {
        var rules: [any GlobalRevocationGroupRule]

        init(rules: [any GlobalRevocationGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: GlobalRevocationGroup) -> [String] {
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

        func requireValid(_ item: GlobalRevocationGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [GlobalRevocationGroup]) -> [String: [String]] {
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

    static func defaultGlobalRevocationGroupValidator() -> GlobalRevocationGroupValidator {
        return GlobalRevocationGroupValidator(
            rules: [
                GlobalRevocationGroupRequiredBedRule(message: "global revocation group needs a value"),
                GlobalRevocationGroupRequiredTitleRule(message: "global revocation group needs this field"),
                GlobalRevocationGroupAllowedTitleRule(allowed: ["primary"]),
                GlobalRevocationGroupCodeLengthRule(maxLength: 86400),
            ]
        )
    }
}
