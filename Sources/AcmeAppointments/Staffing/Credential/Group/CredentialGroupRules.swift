import AcmePlatform
import Foundation

extension Staffing {
    /// A rule a credential group must pass. Check returns its problems, or none.
    protocol CredentialGroupRule {
        func check(_ item: CredentialGroup) -> [String]
    }

    final class CredentialGroupCodeLengthRule: CredentialGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialGroup) -> [String] {
            let size = item.code.count
            if size > maxLength {
                return ["code is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialGroupAllowedCodeRule: CredentialGroupRule {
        var allowed: [String]

        init(allowed: [String]) {
            self.allowed = allowed
        }

        func check(_ item: CredentialGroup) -> [String] {
            if allowed.count == 0 {
                return []
            }
            if !allowed.contains(Kit.Text.normalize(item.code)) {
                return ["code \(item.code) is blocked"]
            }
            return []
        }
    }

    final class CredentialGroupMinimumRangeRule: CredentialGroupRule {
        var min: Double
        var max: Double

        init(min: Double, max: Double) {
            self.min = min
            self.max = max
        }

        func check(_ item: CredentialGroup) -> [String] {
            let value = item.minimum
            var problems: [String] = []
            if value < min {
                problems.append("minimum \(value) is below \(min)")
            }
            if value > max {
                problems.append("minimum \(value) is above \(max)")
            }
            return problems
        }
    }

    final class CredentialGroupBedLengthRule: CredentialGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialGroup) -> [String] {
            let size = item.bed.count
            if size > maxLength {
                return ["bed is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    final class CredentialGroupNameLengthRule: CredentialGroupRule {
        var maxLength: Int

        init(maxLength: Int) {
            self.maxLength = maxLength
        }

        func check(_ item: CredentialGroup) -> [String] {
            let size = item.name.count
            if size > maxLength {
                return ["name is \(size) characters, more than \(maxLength)"]
            }
            return []
        }
    }

    /// Runs every rule of a credential group.
    final class CredentialGroupValidator {
        var rules: [any CredentialGroupRule]

        init(rules: [any CredentialGroupRule]) {
            self.rules = rules
        }

        func validate(_ item: CredentialGroup) -> [String] {
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

        func requireValid(_ item: CredentialGroup) throws {
            let problems = self.validate(item)
            if problems.count > 0 {
                throw Kit.Failure("\(item.label()) is invalid: \(problems.joined(separator: "; "))")
            }
        }

        func validateAll(_ items: [CredentialGroup]) -> [String: [String]] {
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

    static func defaultCredentialGroupValidator() -> CredentialGroupValidator {
        return CredentialGroupValidator(
            rules: [
                CredentialGroupCodeLengthRule(maxLength: 255),
                CredentialGroupAllowedCodeRule(allowed: ["fallback"]),
                CredentialGroupMinimumRangeRule(min: 2.9, max: 4513.5),
                CredentialGroupBedLengthRule(maxLength: 120),
                CredentialGroupNameLengthRule(maxLength: 1000),
            ]
        )
    }
}
