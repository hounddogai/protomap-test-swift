import AcmePlatform
import Foundation

extension Consent {
    /// A rule a revocation group must pass. Check returns its problems, or none.
    protocol RevocationGroupRule {
        func check(_ item: RevocationGroup) -> [String]
    }

    final class RevocationGroupWardLengthRule: RevocationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationGroup) -> [String] {
            let size = item.ward.count
            if size > maxLength {
                return ["ward is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class RevocationGroupRequiredLabelRule: RevocationGroupRule {
        var message: String

        init(message: String) {
            self.message = message
        }

        func check(_ item: RevocationGroup) -> [String] {
            if item.label.trimmingCharacters(in: .whitespaces) == "" {
                return [message]
            }
            return []
        }
    }

    final class RevocationGroupCodeLengthRule: RevocationGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: RevocationGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a revocation group.
    final class RevocationGroupValidator {
        var rules: [any RevocationGroupRule]

        init(rules: [any RevocationGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: RevocationGroup) -> [String] {
            var problems: [String] = []
            for rule in rules {
                for problem in rule.check(item) {
                    problems.append(problem)
                }
            }
            return problems
        }

        func requireValid(_ item: RevocationGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.displayLabel()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [RevocationGroup]) -> [String: [String]] {
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

    static func defaultRevocationGroupValidator() -> RevocationGroupValidator {
        return RevocationGroupValidator(
            rules: [
                RevocationGroupWardLengthRule(maxLength: 1000),
                RevocationGroupRequiredLabelRule(message: "revocation group needs an entry"),
                RevocationGroupCodeLengthRule(maxLength: 1000),
            ]
        )
    }
}
